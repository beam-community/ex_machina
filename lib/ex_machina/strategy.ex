defmodule ExMachina.Strategy do
  @moduledoc ~S"""
  Module for making new strategies for working with factories

  ## Example

      defmodule MyApp.JsonEncodeStrategy do
        # The function_name will be used to generate functions in your factory
        # This example adds json_encode/1, json_encode/2, json_encode_pair/2 and json_encode_list/2
        use ExMachina.Strategy, function_name: :json_encode

        # Define a function for handling the records.
        # Takes the form of "handle_#{function_name}"
        def handle_json_encode(record, _opts) do
          Poison.encode!(record)
        end
      end

      defmodule MyApp.JsonFactory do
        use ExMachina
        use MyApp.JsonEncodeStrategy

        def factory(:user) do
          %User{name: "John"}
        end
      end

      # Will build and then return a JSON encoded version of the user.
      MyApp.JsonFactories.json_encode(:user)

  See `ExMachina.EctoStrategy` in the ExMachina repo to see another example.
  """

  @doc false
  defmacro __using__(function_name: function_name) do
    quote do
      @doc false
      def function_name do
        unquote(function_name)
      end

      defmacro __using__(opts) do
        custom_strategy_module = __MODULE__
        function_name = custom_strategy_module.function_name
        handle_response_function_name = :"handle_#{function_name}"

        quote do
          def unquote(function_name)(already_built_record) when is_map(already_built_record) do
            apply unquote(custom_strategy_module),
              unquote(handle_response_function_name),
              [already_built_record, unquote(opts)]
          end

          def unquote(function_name)(factory_name, attrs \\ %{}) do
            record = ExMachina.build(__MODULE__, factory_name, attrs)

            unquote(function_name)(record)
          end

          def unquote(:"#{function_name}_pair")(factory_name, attrs \\ %{}) do
            unquote(:"#{function_name}_list")(2, factory_name, attrs)
          end

          def unquote(:"#{function_name}_list")(number_of_records, factory_name, attrs \\ %{}) do
            Enum.map 1..number_of_records, fn(_) ->
              unquote(function_name)(factory_name, attrs)
            end
          end
        end
      end
    end
  end

  defmacro __using__(opts) do
    raise """
    expected function_name as an option, instead got #{inspect opts}.

    Example: use ExMachina.Strategy, function_name: :json_encode
    """
  end
end

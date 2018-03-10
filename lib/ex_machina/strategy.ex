defmodule ExMachina.Strategy do
  @moduledoc ~S"""
  Module for making new strategies for working with factories

  ## Example

      defmodule MyApp.JsonEncodeStrategy do
        # The function_name will be used to generate functions in your factory
        # This example adds json_encode/1, json_encode/2, json_encode_pair/2 and json_encode_list/3
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

        def user_factory do
          %User{name: "John"}
        end
      end

      # Will build and then return a JSON encoded version of the user.
      MyApp.JsonFactories.json_encode(:user)

  The arguments sent to the handling function are

    1) The built record
    2) The options passed to the strategy

  The options sent as the second argument are always converted to a map. The
  options are anything you passed when you `use` your strategy in your factory,
  merged together with `%{factory_module: FactoryItWasCalledFrom}`.

  This allows for customizing the strategy, and for calling other functions on
  the factory if needed.

  See `ExMachina.EctoStrategy` in the ExMachina repo, and the docs for
  `name_from_struct/1` for more examples.
  """

  @doc false
  defmacro __using__(function_name: function_name) do
    quote do
      @doc false
      def function_name, do: unquote(function_name)

      defmacro __using__(opts) do
        custom_strategy_module = __MODULE__
        function_name = custom_strategy_module.function_name
        handle_response_function_name = :"handle_#{function_name}"

        quote do
          def unquote(function_name)(already_built_record) when is_map(already_built_record) do
            opts = Map.new(unquote(opts)) |> Map.merge(%{factory_module: __MODULE__})

            apply unquote(custom_strategy_module),
              unquote(handle_response_function_name),
              [already_built_record, opts]
          end

          def unquote(function_name)(factory_name, attrs \\ %{}) do
            record = ExMachina.build(__MODULE__, factory_name, attrs)

            unquote(function_name)(record)
          end

          def unquote(:"#{function_name}_pair")(factory_name, attrs \\ %{}) do
            unquote(:"#{function_name}_list")(2, factory_name, attrs)
          end

          def unquote(:"#{function_name}_list")(number_of_records, factory_name, attrs \\ %{}) do
            Stream.repeatedly(fn ->
              unquote(function_name)(factory_name, attrs)
            end)
            |> Enum.take(number_of_records)
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

  @doc ~S"""
  Returns the factory name from a struct. Useful for strategies with callbacks.

  This function can be useful when you want to call other functions based on the
  type of struct passed in. For example, if you wanted to call a function on the
  factory module before JSON encoding.

  ## Examples

      ExMachina.Strategy.name_from_struct(%User{}) # Returns :user
      ExMachina.Strategy.name_from_struct(%MyUser{}) # Returns :my_user
      ExMachina.Strategy.name_from_struct(%MyApp.MyTask{}) # Returns :my_task

  ## Implementing callback functions with name_from_struct/1

      defmodule MyApp.JsonEncodeStrategy do
        use ExMachina.Strategy, function_name: :json_encode

        def handle_json_encode(record, %{factory_module: factory_module}) do
          # If the record was a %User{} this would return :before_encode_user
          callback_func_name = :"before_encode_#{ExMachina.Strategy.name_from_struct(record)}"

          if callback_defined?(factory_module, callback_func_name) do
            # First call the callback function
            apply(factory_module, callback_func_name, [record])
            # Then encode it
            |> Poison.encode!
          else
            # Otherwise, encode it without calling any callback
            Poison.encode!(record)
          end
        end

        defp callback_defined?(module, func_name) do
          Code.ensure_loaded?(module) && function_exported?(module, func_name, 1)
        end
      end
  """

  @spec name_from_struct(struct) :: atom
  def name_from_struct(%{__struct__: struct_name} = _struct) do
    struct_name
    |> Module.split
    |> List.last
    |> Macro.underscore
    |> String.downcase
    |> String.to_atom
  end
end

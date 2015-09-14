defmodule Anvil do
  defmodule UndefinedFactory do
    defexception [:message]

    def exception(factory_name) do
      message = "No factory defined for #{inspect factory_name}"
      %UndefinedFactory{message: message}
    end
  end

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      def assoc(opts, factory_name) do
        if Map.has_key?(opts, factory_name) do
          Map.get(opts, factory_name)
        else
          create(factory_name)
        end
      end

      def build(factory_name, opts \\ %{}) do
        opts = Enum.into(opts, %{})
        factory(factory_name, opts) |> Map.merge(opts)
      end

      def create(factory_name, opts \\ %{}) do
        build(factory_name, opts) |> create_record
      end

      def create_pair(factory_name, opts \\ %{}) do
        create_list(2, factory_name, opts)
      end

      def create_list(number_of_factorys, factory_name, opts \\ %{}) do
        Enum.map(1..number_of_factorys, fn(_) ->
          create(factory_name, opts)
        end)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Calls factory/1 with the passed in factory name

      This allows you to define factorys without the second `opts` param.
      """
      def factory(factory_name, _opts) do
        __MODULE__.factory(factory_name)
      end

      @doc """
      Raises a helpful error if no factory is defined.
      """
      def factory(factory_name) do
        raise UndefinedFactory, factory_name
      end
    end
  end
end

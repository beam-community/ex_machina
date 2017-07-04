defmodule ExMachina.Factory do
  @moduledoc """
  Define function/macros for grouping factories
  """

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__)
      use ExMachina

      @factories []
    end
  end

  defmacro __before_compile__(_opts) do
    quote unquote: false do
      defmacro __using__(_opts) do
        quote do
          @local_factories unquote(Macro.escape(@factories))

          definitions = quote unquote: false do
            factories = @local_factories
            for {name, generator} <- factories do
              factory unquote(name), do: unquote(generator)
            end
          end

          Code.eval_quoted definitions, [], __ENV__
        end
      end
    end
  end

  defmacro machine(name, do: generator) do
    quote bind_quoted: [
      name: Macro.escape(name, unquote: true),
      generator: Macro.escape(generator, unquote: true)
    ] do
      @factories [{name, generator} | @factories]
      factory unquote(name), do: unquote(generator)
    end
  end
end

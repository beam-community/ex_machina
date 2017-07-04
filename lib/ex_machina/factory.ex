defmodule ExMachina.Factory do
  @moduledoc """
  Define function/macros for grouping factories
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import unquote(__MODULE__)
      use ExMachina

      @factories []
    end
  end

  @doc """
  Hook to define module's __using__ macro
  """
  defmacro __before_compile__(_opts) do
    quote unquote: false do
      defmacro __using__(_opts) do
        quote do
          @local_factories unquote(Macro.escape(@factories))

          # TODO: The definitions were wrapped inside a function and latter on evaluated
          # because I couldn't find a way to bind_quoted que @factories attribute
          # and access it. It seems that Elixir defines the bind_quoted in the context
          # of __using__, then we cannot access it from the exported quoted expression
          definitions = quote unquote: false do
            factories = @local_factories
            for {name, generator} <- factories do
              machine unquote(name), do: unquote(generator)
            end
          end

          Code.eval_quoted definitions, [], __ENV__
        end
      end
    end
  end

  @doc """
  Create a local factory and register it to be exported by __using__
  """
  defmacro factory(name, do: generator) do
    quote bind_quoted: [
      name: Macro.escape(name, unquote: true),
      generator: Macro.escape(generator, unquote: true)
    ] do
      @factories [{name, generator} | @factories]
      machine unquote(name), do: unquote(generator)
    end
  end
end

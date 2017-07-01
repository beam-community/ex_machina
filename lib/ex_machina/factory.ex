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
    quote do
      defmacro __using__(_opts) do
        quote do
          factories = unquote(Macro.escape(@factories))
          IO.puts "Factories for #{unquote(__MODULE__)} -> #{inspect factories}"
          for {name, generator} <- factories do
            factory name, do: generator
          end
        end
      end
    end
  end

  defmacro machine(name, do: generator) do
    quote do
      @factories [{unquote(name), unquote(generator)} | @factories]
      factory unquote(name), do: unquote(generator)
    end
  end
end

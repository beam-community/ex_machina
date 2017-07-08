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
    quote do
      defmacro __using__(_opts) do
        @factories
      end
    end
  end

  @doc """
  Create a local factory and register it to be exported by __using__
  """
  defmacro factory(name, do: generator) do
    factory = generate_factory(name, generator)

    quote do
      @factories [unquote(Macro.escape(factory)) | @factories]
      unquote(factory)
    end
  end

  def generate_factory(name, generator) do
    quote bind_quoted: [
      name: Macro.escape(name, unquote: true),
      generator: Macro.escape(generator, unquote: true)
    ] do
      machine unquote(name), do: unquote(generator)
    end
  end
end

defmodule ExMachina.Factory do
  defstruct [:module, :name, :attrs]

  def build(%{module: module, name: name, attrs: attrs}) do
    ExMachina.build(module, name, attrs)
  end
end

defmodule ExMachina.Instance do
  @moduledoc false

  defstruct [:module, :name, :attrs]

  @doc false
  def build(%{module: module, name: name, attrs: attrs}) do
    ExMachina.build(module, name, attrs)
  end
end

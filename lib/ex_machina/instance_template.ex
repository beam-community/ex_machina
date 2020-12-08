defmodule ExMachina.InstanceTemplate do
  @moduledoc false

  defstruct [:module, :name, :attrs]

  @doc false
  def evaluate(%{module: module, name: name, attrs: attrs}) do
    apply(module, :build, [name, attrs])
  end
end

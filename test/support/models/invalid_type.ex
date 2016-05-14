defmodule ExMachina.InvalidType do
  @behaviour Ecto.Type

  def type, do: :integer

  def cast(_), do: :error
  def load(_), do: :error
  def dump(_), do: :error
end

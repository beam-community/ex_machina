defmodule ExMachina.InvalidType do
  @behaviour Ecto.Type

  def type, do: :integer
  def equal?(_a, _b), do: false
  def embed_as(_), do: :self

  def cast(_), do: :error
  def load(_), do: :error
  def dump(_), do: :error
end

defmodule ExMachina.InvalidCast do
  use Ecto.Schema

  schema "invalid_casts" do
    field :invalid, ExMachina.InvalidType
  end
end

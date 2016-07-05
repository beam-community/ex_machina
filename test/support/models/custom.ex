defmodule ExMachina.Custom do
  use Ecto.Schema

  @primary_key {:custom_id, :integer, []}
  schema "customs" do
    field :name, :string
  end
end


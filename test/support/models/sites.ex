defmodule ExMachina.Site do
  use Ecto.Schema

  schema "sites" do
    field :name, :string
  end
end

defmodule ExMachina.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :admin, :boolean
  end
end

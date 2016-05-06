defmodule ExMachina.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    belongs_to :author, ExMachina.User
  end
end

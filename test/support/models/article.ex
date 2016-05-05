defmodule ExMachina.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string

    belongs_to :author, ExMachina.User
    belongs_to :editor, ExMachina.User
  end
end

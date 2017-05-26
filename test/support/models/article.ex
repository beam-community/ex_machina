defmodule ExMachina.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :visits, :decimal

    belongs_to :author, ExMachina.User
    belongs_to :editor, ExMachina.User
    belongs_to :publisher, ExMachina.Publisher
    has_many :comments, ExMachina.Comment
  end
end

defmodule ExMachina.Article do
  use Ecto.Schema

  import Ecto.Changeset

  schema "articles" do
    field(:title, :string)
    field(:visits, :decimal)

    belongs_to(:author, ExMachina.User)
    belongs_to(:editor, ExMachina.User)
    belongs_to(:publisher, ExMachina.Publisher)
    has_many(:comments, ExMachina.Comment)
  end

  def changeset(article, params \\ %{}) do
    article
    |> cast(params, [:title, :visits])
  end

  def with_author(article, params \\ %{}) do
    article
    |> cast(params, [])
    |> cast_assoc(:author)
  end
end

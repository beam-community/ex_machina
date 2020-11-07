defmodule ExMachina.User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "users" do
    field(:name, :string)
    field(:admin, :boolean)
    field(:net_worth, :decimal)
    field(:password, :string, virtual: true)

    has_many(:articles, ExMachina.Article, foreign_key: :author_id)
    has_many(:editors, through: [:articles, :editor])
    has_one(:best_article, ExMachina.Article, foreign_key: :author_id)
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :admin, :net_worth, :password])
    |> validate_required([:name, :admin, :net_worth, :password])
  end

  def role_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:admin])
    |> validate_required([:admin])
  end

  def with_best_article(user, params \\ %{}) do
    user
    |> cast(params, [])
    |> cast_assoc(:best_article)
  end
end

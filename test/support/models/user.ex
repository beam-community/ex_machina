defmodule ExMachina.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :admin, :boolean

    has_many :articles, ExMachina.Article
    belongs_to :site,   ExMachina.Site
  end
end

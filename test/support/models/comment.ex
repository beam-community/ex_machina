defmodule ExMachina.Comment do
  use Ecto.Schema

  schema "comments" do
    embeds_one :author, ExMachina.Author
    embeds_many :links, ExMachina.Link
  end
end

defmodule ExMachina.Author do
  use Ecto.Schema

  embedded_schema do
    field :name
    field :salary, :decimal
  end
end

defmodule ExMachina.Link do
  use Ecto.Schema

  embedded_schema do
    field :url
    field :rating, :decimal
  end
end

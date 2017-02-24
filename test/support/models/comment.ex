defmodule ExMachina.Comment do
  use Ecto.Schema

  schema "comments" do
    embeds_one :editor, ExMachina.Editor
    embeds_many :links, ExMachina.Link
  end
end

defmodule ExMachina.Editor do
  use Ecto.Schema

  embedded_schema do
    field :name
  end
end

defmodule ExMachina.Link do
  use Ecto.Schema

  embedded_schema do
    field :url
  end
end

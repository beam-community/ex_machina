defmodule ExMachina.Document do
  @moduledoc """
  Test model with polymorphic embed field.
  Simulates a schema using polymorphic_embed library.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "documents" do
    field(:title, :string)
    # This field uses PolymorphicEmbed type which must not be cast with Ecto.Changeset.cast/4
    field(:content, PolymorphicEmbed)
    field(:metadata, PolymorphicEmbed.Phoenix)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title])
    # In real usage, this would call PolymorphicEmbed.cast_polymorphic_embed/2
    # For our test, we just validate the field is present
    |> validate_required([:title])
  end
end

defmodule ExMachina.TextContent do
  @moduledoc """
  Test embedded schema for polymorphic embed content
  """
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:body, :string)
    field(:__type__, :string, default: "text")
  end
end

defmodule ExMachina.ImageContent do
  @moduledoc """
  Test embedded schema for polymorphic embed content
  """
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:alt_text, :string)
    field(:__type__, :string, default: "image")
  end
end

defmodule ExMachina.VideoContent do
  @moduledoc """
  Test embedded schema for polymorphic embed content
  """
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:duration, :integer)
    field(:__type__, :string, default: "video")
  end
end

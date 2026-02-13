defmodule ExMachina.Document do
  @moduledoc """
  Test model with polymorphic embed field using the actual polymorphic_embed library.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import PolymorphicEmbed

  schema "documents" do
    field(:title, :string)
    
    polymorphic_embeds_one :content,
      types: [
        text: ExMachina.TextContent,
        image: ExMachina.ImageContent,
        video: ExMachina.VideoContent
      ],
      on_type_not_found: :raise,
      on_replace: :update
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [:title])
    |> cast_polymorphic_embed(:content)
  end
end

defmodule ExMachina.TextContent do
  @moduledoc """
  Text content type for polymorphic embed
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:body, :string)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:body])
  end
end

defmodule ExMachina.ImageContent do
  @moduledoc """
  Image content type for polymorphic embed
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:alt_text, :string)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:url, :alt_text])
  end
end

defmodule ExMachina.VideoContent do
  @moduledoc """
  Video content type for polymorphic embed
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:url, :string)
    field(:duration, :integer)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:url, :duration])
  end
end

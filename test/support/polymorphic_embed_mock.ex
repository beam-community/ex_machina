defmodule PolymorphicEmbed do
  @moduledoc """
  Mock implementation of PolymorphicEmbed for testing.
  This simulates the behavior of the real polymorphic_embed library.
  """

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(_value) do
    raise """
    Elixir.PolymorphicEmbed must not be casted using Ecto.Changeset.cast/4, 
    use Elixir.PolymorphicEmbed.cast_polymorphic_embed/2 instead.
    """
  end

  @impl Ecto.Type
  def load(value), do: {:ok, value}

  @impl Ecto.Type
  def dump(value), do: {:ok, value}

  @impl Ecto.Type
  def embed_as(_format), do: :self

  @impl Ecto.Type
  def equal?(a, b), do: a == b

  @doc """
  Mock implementation of cast_polymorphic_embed/2
  This would normally be called from the changeset function
  """
  def cast_polymorphic_embed(changeset, field) do
    # In the real implementation, this would properly cast the polymorphic embed
    # For our mock, we just pass through the changeset
    changeset
  end
end

defmodule PolymorphicEmbed.Phoenix do
  @moduledoc """
  Mock Phoenix integration module for PolymorphicEmbed
  """
  
  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(_value) do
    raise """
    Elixir.PolymorphicEmbed.Phoenix must not be casted using Ecto.Changeset.cast/4, 
    use Elixir.PolymorphicEmbed.cast_polymorphic_embed/2 instead.
    """
  end

  @impl Ecto.Type
  def load(value), do: {:ok, value}

  @impl Ecto.Type
  def dump(value), do: {:ok, value}

  @impl Ecto.Type
  def embed_as(_format), do: :self

  @impl Ecto.Type
  def equal?(a, b), do: a == b
end

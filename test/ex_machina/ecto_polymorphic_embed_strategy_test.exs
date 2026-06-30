unless Code.ensure_loaded?(PolymorphicEmbed) do
  defmodule PolymorphicEmbed do
    use Ecto.ParameterizedType

    def type(_params), do: :map
    def init(opts), do: Map.new(opts)
    def cast(_value, _params), do: :error
    def load(value, _loader, _params), do: {:ok, value}
    def dump(value, _dumper, _params), do: {:ok, value}
  end
end

defmodule ExMachina.PolymorphicEmbedTestRepo do
  def insert!(record), do: record
  def insert!(record, opts), do: {:inserted, record, opts}
end

defmodule ExMachina.CurrentPolymorphicEmbedSchema do
  use Ecto.Schema

  schema "current_polymorphic_embed_schemas" do
    field(:amount, :decimal)
    field(:payload, PolymorphicEmbed)
    field(:payloads, {:array, PolymorphicEmbed})
  end
end

defmodule ExMachina.LegacyPolymorphicEmbedSchema do
  defstruct [:__meta__, :amount, :payload, :payloads]

  def __schema__(:fields), do: [:amount, :payload, :payloads]
  def __schema__(:embeds), do: []
  def __schema__(:associations), do: []

  def __schema__(:type, :amount), do: :decimal
  def __schema__(:type, :payload), do: {:parameterized, PolymorphicEmbed, %{}}
  def __schema__(:type, :payloads), do: {:array, {:parameterized, PolymorphicEmbed, %{}}}
end

defmodule ExMachina.EctoPolymorphicEmbedTestFactory do
  use ExMachina.EctoPolymorphicEmbed, repo: ExMachina.PolymorphicEmbedTestRepo

  def current_polymorphic_embed_factory do
    %ExMachina.CurrentPolymorphicEmbedSchema{
      amount: 300,
      payload: %{type: "one"},
      payloads: [%{type: "many"}]
    }
  end

  def legacy_polymorphic_embed_factory do
    %ExMachina.LegacyPolymorphicEmbedSchema{
      __meta__: %Ecto.Schema.Metadata{
        state: :built,
        source: "legacy_polymorphic_embed_schemas",
        schema: ExMachina.LegacyPolymorphicEmbedSchema
      },
      amount: 300,
      payload: %{type: "one"},
      payloads: [%{type: "many"}]
    }
  end
end

defmodule ExMachina.EctoPolymorphicEmbedStrategyTest do
  use ExUnit.Case, async: true

  alias ExMachina.EctoPolymorphicEmbedTestFactory

  test "insert/1 skips current parameterized polymorphic embed fields" do
    model = EctoPolymorphicEmbedTestFactory.insert(:current_polymorphic_embed)

    assert model.amount == Decimal.new(300)
    assert model.payload == %{type: "one"}
    assert model.payloads == [%{type: "many"}]
  end

  test "insert/1 skips legacy parameterized polymorphic embed fields" do
    model = EctoPolymorphicEmbedTestFactory.insert(:legacy_polymorphic_embed)

    assert model.amount == Decimal.new(300)
    assert model.payload == %{type: "one"}
    assert model.payloads == [%{type: "many"}]
  end

  test "insert/3 passes options to the repo" do
    assert {:inserted, model, [returning: true]} =
             EctoPolymorphicEmbedTestFactory.insert(
               :current_polymorphic_embed,
               %{},
               returning: true
             )

    assert model.amount == Decimal.new(300)
  end
end

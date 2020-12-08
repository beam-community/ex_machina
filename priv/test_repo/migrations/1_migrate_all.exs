defmodule ExMachina.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:admin, :boolean)
      add(:net_worth, :decimal)
    end

    create table(:publishers) do
      add(:pub_number, :string)
    end

    create(unique_index(:publishers, [:pub_number]))

    create table(:articles) do
      add(:title, :string)
      add(:author_id, :integer)
      add(:editor_id, :integer)
      add(:publisher_id, :integer)
      add(:visits, :decimal)
    end

    create table(:comments) do
      add(:article_id, :integer)
      add(:author, :map)
      add(:links, {:array, :map}, default: [])
    end
  end
end

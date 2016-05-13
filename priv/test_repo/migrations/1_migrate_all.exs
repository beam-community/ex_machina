defmodule ExMachina.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :name, :string
    end

    create table(:users) do
      add :name, :string
      add :admin, :boolean
      add :site_id, :integer
    end

    create table(:articles) do
      add :title, :string
      add :author_id, :integer
      add :editor_id, :integer
      add :site_id, :integer
    end
  end
end

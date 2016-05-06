defmodule ExMachina.TestRepo.Migrations.MigrateAll do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :admin, :boolean
    end

    create table(:articles) do
      add :title, :string
      add :author_id, :integer
    end
  end
end

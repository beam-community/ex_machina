defmodule ExMachina.TestRepo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :admin, :boolean
      add :token, :string
    end
  end
end

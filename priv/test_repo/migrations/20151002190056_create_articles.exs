defmodule ExMachina.TestRepo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string
      add :author_id, :integer
    end
  end
end

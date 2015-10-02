defmodule ExMachina.TestRepo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :string
      add :user_id, :integer
      add :article_id, :integer
    end
  end
end

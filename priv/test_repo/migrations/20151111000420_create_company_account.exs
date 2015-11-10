defmodule ExMachina.TestRepo.Migrations.CreateCompanyAccount do
  use Ecto.Migration

  def change do
    create table(:company_accounts) do
      add :name, :string
      add :manager_id, :integer
    end
  end
end

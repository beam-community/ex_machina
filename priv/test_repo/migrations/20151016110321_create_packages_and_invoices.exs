defmodule ExMachina.TestRepo.Migrations.CreatePackagesAndInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :title, :string
      add :package_id, :integer
    end
    create table(:package_statuses) do
      add :status, :string
      add :package_id, :integer
    end
    create table(:packages) do
      add :description, :string
    end
  end
end

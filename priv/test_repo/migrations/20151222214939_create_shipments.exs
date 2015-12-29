defmodule ExMachina.TestRepo.Migrations.CreateShipments do
  use Ecto.Migration

  def change do
    create table(:shipments) do
      add :name, :string
    end

    alter table(:packages) do
      add :shipment_id, :integer
    end
  end
end

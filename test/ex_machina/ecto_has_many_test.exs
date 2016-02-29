defmodule ExMachina.EctoHasManyTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule Package do
    use Ecto.Schema
    schema "packages" do
      field :description, :string
      has_many :statuses, ExMachina.EctoHasManyTest.PackageStatus

      belongs_to :shipment, Shipment
    end
  end

  defmodule PackageStatus do
    use Ecto.Schema
    schema "package_statuses" do
      field :status, :string
      belongs_to :package, Package
    end
  end

  defmodule Factory do
    use ExMachina.Ecto, repo: TestRepo

    def factory(:package) do
      %Package{
        description: "Package that just got ordered",
        statuses: [
          build(:package_status, status: "ordered")
        ]
      }
    end

    def factory(:package_status) do
      %PackageStatus{
        status: "ordered"
      }
    end
  end

  test "create/1 saves `has_many` records defined in the factory" do
    package = Factory.create(:package)

    assert %{statuses: [%{status: "ordered"}]} = package
  end

  test "create/2 saves overriden `has_many` associations" do
    statuses = [
      Factory.build(:package_status, status: "ordered"),
      Factory.build(:package_status, status: "delayed")
    ]
    package = Factory.create(:package, statuses: statuses)

    statuses = TestRepo.all(PackageStatus)
    assert package.statuses == statuses
    assert [%{status: "ordered"}, %{status: "delayed"}] = statuses
  end
end

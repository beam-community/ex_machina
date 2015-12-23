defmodule ExMachina.EctoHasManyTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule Package do
    use Ecto.Model
    schema "packages" do
      field :description, :string
      has_many :statuses, ExMachina.EctoHasManyTest.PackageStatus
      has_many :invoices, ExMachina.EctoHasManyTest.Invoice
    end
  end

  defmodule PackageStatus do
    use Ecto.Model
    schema "package_statuses" do
      field :status, :string
      belongs_to :package, Package
    end
  end

  defmodule Invoice do
    use Ecto.Model
    schema "invoices" do
      field :title, :string
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

    def factory(:shipped_package) do
      %Package{
        description: "Package that got shipped",
        statuses: [
          build(:package_status, status: "ordered"),
          build(:package_status, status: "sent"),
          build(:package_status, status: "shipped")
        ]
      }
    end

    def factory(:package_status) do
      %PackageStatus{
        status: "ordered"
      }
    end

    def factory(:invoice) do
      %Invoice{
        title: "Invoice for shipped package",
        package: build(:shipped_package)
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

  test "create/1 creates a record without any associations" do
    package = Factory.create(:package, statuses: [])
    assert package
  end

  test "create/1 creates model with `belongs_to` that `has_many` associations" do
    invoice = Factory.create(:invoice)

    saved_package = TestRepo.one(Package)
    assert invoice.title == "Invoice for shipped package"
    assert invoice.package_id == saved_package.id
    assert length(invoice.package.statuses) == 3
  end

  test "create/1 saves when a has many association is not loaded" do
    package = Factory.create(:package, invoices: %Ecto.Association.NotLoaded{})
    assert package
  end
end

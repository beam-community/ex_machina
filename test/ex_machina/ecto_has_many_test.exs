defmodule ExMachina.EctoHasManyTest do
  use ExUnit.Case, async: false
  alias ExMachina.TestRepo

  setup_all do
    Ecto.Adapters.SQL.begin_test_transaction(TestRepo, [])
    on_exit fn -> Ecto.Adapters.SQL.rollback_test_transaction(TestRepo, []) end
    :ok
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestRepo, [])
    :ok
  end

  defmodule Package do
    use Ecto.Model
    schema "packages" do
      field :description, :string
      has_many :statuses, ExMachina.EctoHasManyTest.PackageStatus
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

    factory(:invalid_package) do
      %Package{
        description: "Invalid package without any statuses"
      }
    end

    factory(:package) do
      %Package{
        description: "Package that just got ordered",
        statuses: [
          %PackageStatus{status: "ordered"}
        ]
      }
    end

    factory(:shipped_package) do
      %Package{
        description: "Package that got shipped",
        statuses: [
          %PackageStatus{status: "ordered"},
          %PackageStatus{status: "sent"},
          %PackageStatus{status: "shipped"}
        ]
      }
    end

    factory(:invoice) do
      %Invoice{
        title: "Invoice for shipped package",
        package: assoc(:package, factory: :shipped_package)
      }
    end
  end

  test "create/1 creates model with `has_many` associations" do
    package = Factory.create(:package)

    assert %{statuses: [%{status: "ordered"}]} = package
  end

  test "create/2 creates model with overriden `has_many` associations" do
    statuses = [
      %PackageStatus{status: "ordered"},
      %PackageStatus{status: "delayed"}
    ]
    package = Factory.create :package,
      description: "Delayed package",
      statuses: statuses

    assert %{statuses: [%{status: "ordered"}, %{status: "delayed"}]} = package
  end

  test "create/1 creates model without `has_many` association specified" do
    package = Factory.create(:invalid_package)
    assert package
  end

  test "create/1 creates model with `belongs_to` having `has_many` associations" do
    invoice = Factory.create(:invoice)

    assert %{title: "Invoice for shipped package", package_id: 1} = invoice
  end
end

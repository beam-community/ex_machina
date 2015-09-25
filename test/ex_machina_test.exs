defmodule ExMachinaTest do
  use ExUnit.Case, async: true

  defmodule MyApp.Factories do
    use ExMachina

    factory :user do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    factory :email do
      %{
        email: sequence(:email, &"me-#{&1}@foo.com")
      }
    end

    def save_record(record) do
      send self, {:custom_save, record}
      record
    end
  end

  defmodule MyApp.NoSaveFunction do
    use ExMachina

    factory(:foo) do
      %{foo: :bar}
    end
  end

  test "sequence/2 sequences a value" do
    assert "me-0@foo.com" == MyApp.Factories.build(:email).email
    assert "me-1@foo.com" == MyApp.Factories.build(:email).email
  end

  test "raises a helpful error if the factory is not defined" do
    assert_raise ExMachina.UndefinedFactory, "No factory defined for :foo", fn ->
      MyApp.Factories.build(:foo)
    end
  end

  test "build/2 returns the matching factory" do
    assert MyApp.Factories.build(:user) == %{
      id: 3,
      name: "John Doe",
      admin: false
    }
  end

  test "build/2 merges passed in options as keyword list" do
    assert MyApp.Factories.build(:user, admin: true) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "build/2 merges passed in options as a map" do
    assert MyApp.Factories.build(:user, admin: true) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "build_pair/2 builds 2 factories" do
    records = MyApp.Factories.build_pair(:user, admin: true)

    expected_record = %{
      id: 3,
      name: "John Doe",
      admin: true
    }
    assert records == [expected_record, expected_record]
  end

  test "build_list/3 builds the factory the passed in number of times" do
    records = MyApp.Factories.build_list(3, :user, admin: true)

    expected_record = %{
      id: 3,
      name: "John Doe",
      admin: true
    }
    assert records == [expected_record, expected_record, expected_record]
  end

  test "create/2 builds factory and performs save with user defined save_record/1" do
    record = MyApp.Factories.create(:user)

    created_record = %{admin: false, id: 3, name: "John Doe"}
    assert record == created_record
    assert_received {:custom_save, ^created_record}
  end

  test "create/2 saves built records" do
    record = MyApp.Factories.build(:user) |> MyApp.Factories.create

    created_record = %{admin: false, id: 3, name: "John Doe"}
    assert record == created_record
    assert_received {:custom_save, ^created_record}
    refute_received {:custom_save}
  end

  test "create/2 raises a helpful error if save_record/1 is not defined" do
    assert_raise ExMachina.UndefinedSave, fn ->
      MyApp.NoSaveFunction.create(:foo)
    end
  end

  test "create_pair/2 creates the factory and saves it 2 times" do
    records = MyApp.Factories.create_pair(:user)

    created_record = %{admin: false, id: 3, name: "John Doe"}
    assert records == [created_record, created_record]
    assert_received {:custom_save, ^created_record}
    assert_received {:custom_save, ^created_record}
    refute_received {:custom_save, _}
  end

  test "create_list/3 creates factory and saves it passed in number of times" do
    records = MyApp.Factories.create_list(3, :user)

    created_record = %{admin: false, id: 3, name: "John Doe"}
    assert records == [created_record, created_record, created_record]
    assert_received {:custom_save, ^created_record}
    assert_received {:custom_save, ^created_record}
    assert_received {:custom_save, ^created_record}
    refute_received {:custom_save, _}
  end
end

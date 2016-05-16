defmodule ExMachinaTest do
  use ExUnit.Case

  defmodule Factory do
    use ExMachina

    def user_factory do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    def email_factory do
      %{
        email: sequence(:email, &"me-#{&1}@foo.com")
      }
    end

    def article_factory do
      %{
        title: sequence("Post Title")
      }
    end

    def struct_factory do
      %{
        __struct__: Foo.Bar
      }
    end

    def lazy_hero_factory do
      %{
        name: "Bat",
        nickname: &"#{&1.name}man",
        vehicles: [
          fn(hero) ->
            build(
              :vehicle,
              name: "#{hero.name}mobile",
              speed: fn(vehicle) ->
                if vehicle.name == "Batmobile" do
                  "very fast"
                else
                  "fast"
                end
              end
            )
          end
        ]
      }
    end

    def vehicle_factory do
      %{
        name: "Car",
        speed: "slow"
      }
    end

    defmodule MyStruct do
      defstruct [:is_safe]
    end

    def exploding_struct_factory do
      %MyStruct{
        is_safe: fn(_) -> raise("It exploded") end
      }
    end
  end

  test "sequence/2 sequences a value" do
    assert "me-0@foo.com" == Factory.build(:email).email
    assert "me-1@foo.com" == Factory.build(:email).email
  end

  test "sequence/1 shortcut for creating sequences" do
    assert "Post Title0" == Factory.build(:article).title
    assert "Post Title1" == Factory.build(:article).title
  end

  test "raises a helpful error if the factory is not defined" do
    assert_raise ExMachina.UndefinedFactoryError, fn ->
      Factory.build(:foo)
    end
  end

  test "build/2 returns the matching factory" do
    assert Factory.build(:user) == %{
      id: 3,
      name: "John Doe",
      admin: false
    }
  end

  test "build/2 merges passed in options as keyword list" do
    assert Factory.build(:user, admin: true) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "build/2 merges passed in options as a map" do
    assert Factory.build(:user, %{admin: true}) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "build/2 raises if passing invalid keys to a struct factory" do
    assert_raise KeyError, fn ->
      Factory.build(:struct, doesnt_exist: true)
    end
  end

  test "build/2 resolves lazy values (functions) when no attributes are given" do
    assert Factory.build(:lazy_hero) == %{
      name: "Bat",
      nickname: "Batman",
      vehicles: [
        %{
          name: "Batmobile",
          speed: "very fast"
        }
      ]
    }
  end

  test "build/2 resolves lazy values (functions) when attributes are passed" do
    assert Factory.build(:lazy_hero, name: "Super") == %{
      name: "Super",
      nickname: "Superman",
      vehicles: [
        %{
          name: "Supermobile",
          speed: "fast"
        }
      ]
    }
  end

  test "build/2 resolves lazy values (functions) that are passed as attributes" do
    assert Factory.build(:lazy_hero, name: "Wonder", nickname: &("#{&1.name}woman")) == %{
      name: "Wonder",
      nickname: "Wonderwoman",
      vehicles: [
        %{
          name: "Wondermobile",
          speed: "fast"
        }
      ]
    }
  end

  test "build/2 with a lazy value (function) does not apply the function if the attribute is overwritten" do
    assert Factory.build(:exploding_struct, is_safe: true) == %Factory.MyStruct{is_safe: true}
  end

  test "build_pair/2 builds 2 factories" do
    records = Factory.build_pair(:user, admin: true)

    expected_record = %{
      id: 3,
      name: "John Doe",
      admin: true
    }
    assert records == [expected_record, expected_record]
  end

  test "build_list/3 builds the factory the passed in number of times" do
    records = Factory.build_list(3, :user, admin: true)

    expected_record = %{
      id: 3,
      name: "John Doe",
      admin: true
    }
    assert records == [expected_record, expected_record, expected_record]
  end

  test "raises helpful error when using old create functions" do
    assert_raise RuntimeError, ~r/create\/1 has been removed/, fn ->
      Factory.create(:user)
    end

    assert_raise RuntimeError, ~r/create\/2 has been removed/, fn ->
      Factory.create(:user, admin: true)
    end

    assert_raise RuntimeError, ~r/create_pair\/2 has been removed/, fn ->
      Factory.create_pair(:user, admin: true)
    end

    assert_raise RuntimeError, ~r/create_list\/3 has been removed/, fn ->
      Factory.create_list(3, :user, admin: true)
    end
  end
end

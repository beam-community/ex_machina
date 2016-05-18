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

    def exploding_factory do
      %{
        is_safe: fn(_) -> raise("It exploded") end
      }
    end

    def deferred_factory do
      %{
        n: "N",
        n2: defer(&(&1.n <> &1.n)),
        n4: defer(1, &(&1.n2 <> &1.n2)),
        n8: defer(2, &(&1.n4 <> &1.n4)),
      }
    end

    def bad_weight_deferred_factory, do: %{n: defer("foo", &(&1))}
    def bad_func_deferred_factory, do: %{n: defer(1, "foo")}
    def bad_arity_deferred_factory, do: %{n: defer(1, fn -> "foo" end)}
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
    assert_raise RuntimeError, fn ->
      Factory.build(:exploding)
    end
    assert Factory.build(:exploding, is_safe: true) == %{is_safe: true}
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

  test "factory using defer/1 and defer/2 generates `DeferredAttribute` structs with correct weights and functions" do
    factory = Factory.deferred_factory

    assert %ExMachina.DeferredAttribute{weight: 0} = factory.n2
    assert %ExMachina.DeferredAttribute{weight: 1} = factory.n4
    assert %ExMachina.DeferredAttribute{weight: 2} = factory.n8
    assert is_function(factory.n2.func, 1)
    assert is_function(factory.n4.func, 1)
    assert is_function(factory.n8.func, 1)
  end

  test "factory using defer/2 with a non-numeric first argument raises ArgumentError" do
    assert_raise ArgumentError,
      "The first argument must be a number.  You gave: \"foo\"",
      fn -> Factory.bad_weight_deferred_factory end
  end

  test "factory using defer/2 with a non-function for the second argument raises ArgumentError" do
    assert_raise ArgumentError,
      "The second argument must be a function with arity 1.  You gave: \"foo\"",
      fn -> Factory.bad_func_deferred_factory end
  end

  test "factory using defer/2 with a function with the wrong arity raises ArgumentError" do
    assert_raise ArgumentError,
      ~r/The second argument must be a function with arity 1.  You gave: #Function/,
      fn -> Factory.bad_arity_deferred_factory end
  end

  test "build/2 with deferred attributes and no overrides computes the attributes correctly" do
    factory = Factory.build(:deferred)
    assert factory.n == "N"
    assert factory.n2 == "NN"
    assert factory.n4 == "NNNN"
    assert factory.n8 == "NNNNNNNN"
  end

  test "build/2 with deferred attributes and overrides given computes the attributes correctly" do
    factory = Factory.build(:deferred, n4: "X")
    assert factory.n == "N"
    assert factory.n2 == "NN"
    assert factory.n4 == "X"
    assert factory.n8 == "XX"
  end
end

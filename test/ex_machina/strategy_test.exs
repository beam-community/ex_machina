defmodule ExMachina.StrategyTest do
  use ExUnit.Case

  defmodule FakeJsonStrategy do
    use ExMachina.Strategy, function_name: :json_encode

    def handle_json_encode(record, opts) do
      send self, {:handle_json_encode, record, opts}
    end
  end

  defmodule Factory do
    use ExMachina
    use FakeJsonStrategy, foo: :bar

    def factory(:user) do
      %{
        name: "John"
      }
    end
  end

  test "defines functions based on the strategy name" do
    strategy_options = [foo: :bar]

    Factory.build(:user) |> Factory.json_encode
    built_user = Factory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode(:user)
    built_user = Factory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode(:user, name: "Jane")
    built_user = Factory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode_pair(:user)
    built_user = Factory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode_pair(:user, name: "Jane")
    built_user = Factory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode_list(3, :user)
    built_user = Factory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    Factory.json_encode_list(3, :user, name: "Jane")
    built_user = Factory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}
  end
end

defmodule ExMachina.StrategyTest do
  use ExUnit.Case

  defmodule FakeJsonStrategy do
    use ExMachina.Strategy, function_name: :json_encode

    def handle_json_encode(record, opts) do
      send self(), {:handle_json_encode, record, opts}
    end
  end

  defmodule JsonFactory do
    use ExMachina
    use FakeJsonStrategy, foo: :bar

    def user_factory do
      %{
        name: "John"
      }
    end
  end

  test "name_from_struct returns the factory name based on passed in struct" do
    assert ExMachina.Strategy.name_from_struct(%{__struct__: User}) == :user
    assert ExMachina.Strategy.name_from_struct(%{__struct__: TwoWord}) == :two_word
    assert ExMachina.Strategy.name_from_struct(%{__struct__: NameSpace.TwoWord}) == :two_word
  end

  test "defines functions based on the strategy name" do
    strategy_options = %{foo: :bar, factory_module: JsonFactory}

    JsonFactory.build(:user) |> JsonFactory.json_encode
    built_user = JsonFactory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode(:user)
    built_user = JsonFactory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode(:user, name: "Jane")
    built_user = JsonFactory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode_pair(:user)
    built_user = JsonFactory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode_pair(:user, name: "Jane")
    built_user = JsonFactory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode_list(3, :user)
    built_user = JsonFactory.build(:user)
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}

    JsonFactory.json_encode_list(3, :user, name: "Jane")
    built_user = JsonFactory.build(:user, name: "Jane")
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    assert_received {:handle_json_encode, ^built_user, ^strategy_options}
    refute_received {:handle_json_encode, _, _}
  end
end

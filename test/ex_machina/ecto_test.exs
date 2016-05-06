defmodule ExMachina.EctoTest do
  use ExMachina.EctoCase

  alias ExMachina.TestFactory
  alias ExMachina.User

  test "raises helpful error message if no repo is provided" do
    message =
      """
      expected :repo to be given as an option. Example:

      use ExMachina.Ecto, repo: MyApp.Repo
      """
    assert_raise ArgumentError, message, fn ->
      defmodule EctoWithNoRepo do
        use ExMachina.Ecto
      end
    end
  end

  test "insert, insert_pair and insert_list work as expected" do
    assert %User{} = TestFactory.build(:user) |> TestFactory.insert
    assert %User{} = TestFactory.insert(:user)
    assert %User{} = TestFactory.insert(:user, admin: true)

    assert [%User{}, %User{}] = TestFactory.insert_pair(:user)
    assert [%User{}, %User{}] = TestFactory.insert_pair(:user, admin: true)

    assert [%User{}, %User{}, %User{}] = TestFactory.insert_list(3, :user)
    assert [%User{}, %User{}, %User{}] = TestFactory.insert_list(3, :user, admin: true)
  end

  test "params_for/2 removes Ecto specific fields" do
    assert TestFactory.params_for(:user) == %{
      name: "John Doe",
      admin: false
    }
  end

  test "params_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      TestFactory.params_for(:user_map)
    end
  end
end

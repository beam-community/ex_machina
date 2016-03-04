defmodule ExMachina.EctoTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule User do
    use Ecto.Schema
    schema "users" do
      field :name, :string
      field :admin, :boolean
    end
  end

  defmodule Factory do
    use ExMachina.Ecto, repo: TestRepo

    def factory(:user) do
      %User{
        name: "John Doe",
        admin: false
      }
    end

    def factory(:user_map) do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end
  end

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
    assert %User{} = Factory.build(:user) |> Factory.insert
    assert %User{} = Factory.insert(:user)
    assert %User{} = Factory.insert(:user, admin: true)

    assert [%User{}, %User{}] = Factory.insert_pair(:user)
    assert [%User{}, %User{}] = Factory.insert_pair(:user, admin: true)

    assert [%User{}, %User{}, %User{}] = Factory.insert_list(3, :user)
    assert [%User{}, %User{}, %User{}] = Factory.insert_list(3, :user, admin: true)
  end

  test "params_for/2 removes Ecto specific fields" do
    assert Factory.params_for(:user) == %{
      id: nil,
      name: "John Doe",
      admin: false
    }
  end

  test "params_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      Factory.params_for(:user_map)
    end
  end
end

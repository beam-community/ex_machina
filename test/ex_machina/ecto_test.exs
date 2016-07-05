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

  test "params_for/2 leaves ids that are not auto-generated" do
    assert TestFactory.params_for(:custom) == %{
      custom_id: 1,
      name: "Testing"
    }
  end

  test "params_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      TestFactory.params_for(:user_map)
    end
  end

  test "params_with_assocs/2 inserts belongs_tos that are set by the factory" do
    assert has_association_in_schema?(ExMachina.Article, :editor)

    assert TestFactory.params_with_assocs(:article) == %{
      title: "My Awesome Article",
      author_id: ExMachina.TestRepo.one!(User).id,
    }
  end

  test "params_with_assocs/2 doesn't insert unloaded assocs" do
    not_loaded = %{__struct__: Ecto.Association.NotLoaded}

    assert TestFactory.params_with_assocs(:article, editor: not_loaded) == %{
      title: "My Awesome Article",
      author_id: ExMachina.TestRepo.one!(User).id,
    }
  end

  test "params_with_assocs/2 doesn't try to save has_many fields" do
    assert has_association_in_schema?(ExMachina.User, :articles)

    assert TestFactory.params_with_assocs(:user) == %{
      admin: false,
      name: "John Doe",
    }
  end

  defp has_association_in_schema?(model, association_name) do
    Enum.member?(model.__schema__(:associations), association_name)
  end
end

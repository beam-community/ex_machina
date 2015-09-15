defmodule ExMachinaTest do
  use ExUnit.Case, async: true

  defmodule TestRepo do
    def insert!(record) do
      send self, {:created, record}
      record
    end
  end

  defmodule MyApp.ExMachina do
    use ExMachina, repo: TestRepo

    def factory(:user) do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    def factory(:account) do
      %{
        id: 100,
        plan_type: "enterprise"
      }
    end

    def factory(:email) do
      %{
        email: sequence(:email, &"me-#{&1}@foo.com")
      }
    end

    def factory(:article, attrs) do
      %{
        id: 1,
        title: "My Awesome Article",
        author_id: assoc(attrs, :author, factory: :user).id
      }
    end

    def factory(:comment, attrs) do
      %{
        body: "This is great!",
        article_id: assoc(attrs, :article).id
      }
    end
  end

  defmodule MyApp.NonEctoFactories do
    use ExMachina

    def factory(:foo), do: %{foo: :bar}

    def save_function(record) do
      send self, {:custom_save, record}
      record
    end
  end

  defmodule MyApp.NoSaveFunction do
    use ExMachina

    def factory(:foo), do: %{foo: :bar}
  end

  test "sequence/2 sequences a value" do
    assert "me-0@foo.com" == MyApp.ExMachina.build(:email).email
    assert "me-1@foo.com" == MyApp.ExMachina.build(:email).email
  end

  test "assoc/3 returns the passed in key if it exists" do
    existing_account = %{id: 1, plan_type: "free"}
    attrs = %{account: existing_account}

    assert ExMachina.assoc(MyApp.ExMachina, attrs, :account) == existing_account
    refute_received {:created, _}
  end

  test "assoc/3 creates and returns a factory if one was not in attrs" do
    attrs = %{}

    account = ExMachina.assoc(MyApp.ExMachina, attrs, :account)

    newly_created_account = %{id: 100, plan_type: "enterprise"}
    assert account == newly_created_account
    assert_received {:created, ^newly_created_account}
  end

  test "assoc/3 can specify a factory for the association" do
    attrs = %{}

    account = ExMachina.assoc(MyApp.ExMachina, attrs, :account, factory: :user)

    newly_created_account = %{id: 3, admin: false, name: "John Doe"}
    assert account == newly_created_account
    assert_received {:created, ^newly_created_account}
  end

  test "can use assoc/3 in a factory to override associations" do
    my_article = MyApp.ExMachina.create(:article, title: "So Deep")

    comment = MyApp.ExMachina.create(:comment, article: my_article)

    assert comment.article == my_article
  end

  test "factories can be defined without the attrs param" do
    assert MyApp.ExMachina.build(:user) == MyApp.ExMachina.factory(:user)
  end

  test "raises a helpful error if the factory is not defined" do
    assert_raise ExMachina.UndefinedFactory, "No factory defined for :foo", fn ->
      MyApp.ExMachina.build(:foo)
    end
  end

  test "build/2 returns the matching factory" do
    assert MyApp.ExMachina.build(:user) == %{
      id: 3,
      name: "John Doe",
      admin: false
    }
  end

  test "build/2 merges passed in options as keyword list" do
    assert MyApp.ExMachina.build(:user, admin: true) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "build/2 merges passed in options as a map" do
    assert MyApp.ExMachina.build(:user, admin: true) == %{
      id: 3,
      name: "John Doe",
      admin: true
    }
  end

  test "create/2 builds the factory and saves it in the repo" do
    user = MyApp.ExMachina.create(:user, admin: true)

    assert user == %{id: 3, name: "John Doe", admin: true}
    assert_received {:created, %{name: "John Doe", admin: true}}
  end

  test "create/2 builds factory and performs custom save if repo is not set" do
    record = MyApp.NonEctoFactories.create(:foo)

    assert record == %{foo: :bar}
    assert_received {:custom_save, %{foo: :bar}}
  end

  test "create/2 raises a helpful error if no repo and no custom function" do
    assert_raise ExMachina.UndefinedSave, fn ->
      MyApp.NoSaveFunction.create(:foo)
    end
  end

  test "create_pair/2 creates the factory and saves it 2 times" do
    users = MyApp.ExMachina.create_pair(:user, admin: true)

    created_user = %{id: 3, name: "John Doe", admin: true}
    assert users == [created_user, created_user]
    assert_received {:created, ^created_user}
    assert_received {:created, ^created_user}
    refute_received {:created, _}
  end

  test "create_list/3 creates factory and saves it passed in number of times" do
    users = MyApp.ExMachina.create_list(3, :user, admin: true)

    created_user = %{id: 3, name: "John Doe", admin: true}
    assert users == [created_user, created_user, created_user]
    assert_received {:created, ^created_user}
    assert_received {:created, ^created_user}
    assert_received {:created, ^created_user}
    refute_received {:created, _}
  end
end

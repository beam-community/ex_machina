defmodule ExMachina.EctoTest do
  use ExUnit.Case, async: true

  defmodule TestRepo do
    def insert!(record) do
      send self, {:created, record}
      record
    end
  end

  defmodule MyApp.Book do
    defstruct title: nil, publisher: nil, __meta__: %{__struct__: Ecto.Schema.Metadata}, publisher_id: 1

    def __schema__(:associations) do
      [:publisher]
    end
  end

  defmodule MyApp.EctoFactories do
    use ExMachina.Ecto, repo: TestRepo

    factory :book do
      %MyApp.Book{
        title: "Foo"
      }
    end

    factory :user do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    factory :article do
      %{
        id: 1,
        title: "My Awesome Article",
        author_id: assoc(:author, factory: :user).id
      }
    end

    factory :comment do
      %{
        body: "This is great!",
        article_id: assoc(:article).id
      }
    end
  end

  test "raises error if no repo is provided" do
    assert_raise KeyError, "key :repo not found in: []", fn ->
      defmodule MyApp.EctoWithNoRepo do
        use ExMachina.Ecto
      end
    end
  end

  test "fields_for/2 removes Ecto specific fields" do
    assert MyApp.EctoFactories.fields_for(:book) == %{
      title: "Foo",
      publisher_id: 1,
    }
  end

  test "fields_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      MyApp.EctoFactories.fields_for(:user)
    end
  end

  test "save_record/1 passes the data to @repo.insert!" do
    record = MyApp.EctoFactories.save_record(%{foo: "bar"})

    assert record == %{foo: "bar"}
    assert_received {:created, %{foo: "bar"}}
  end

  test "assoc/3 returns the passed in key if it exists" do
    existing_account = %{id: 1, plan_type: "free"}
    attrs = %{account: existing_account}

    assert ExMachina.Ecto.assoc(MyApp.EctoFactories, attrs, :account) == existing_account
    refute_received {:created, _}
  end

  test "assoc/3 creates and returns a factory if one was not in attrs" do
    attrs = %{}

    user = ExMachina.Ecto.assoc(MyApp.EctoFactories, attrs, :user)

    created_user = %{id: 3, name: "John Doe", admin: false}
    assert user == created_user
    assert_received {:created, ^created_user}
  end

  test "assoc/3 can specify a factory for the association" do
    attrs = %{}

    account = ExMachina.Ecto.assoc(MyApp.EctoFactories, attrs, :account, factory: :user)

    newly_created_account = %{id: 3, admin: false, name: "John Doe"}
    assert account == newly_created_account
    assert_received {:created, ^newly_created_account}
  end

  test "can use assoc/3 in a factory to override associations" do
    my_article = MyApp.EctoFactories.create(:article, title: "So Deep")

    comment = MyApp.EctoFactories.create(:comment, article: my_article)

    assert comment.article == my_article
  end
end

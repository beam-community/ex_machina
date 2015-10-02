defmodule ExMachina.EctoTest do
  use ExUnit.Case, async: true
  alias ExMachina.TestRepo

  setup_all do
    Ecto.Adapters.SQL.begin_test_transaction(TestRepo, [])
    on_exit fn -> Ecto.Adapters.SQL.rollback_test_transaction(TestRepo, []) end
    :ok
  end

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestRepo, [])
    :ok
  end

  defmodule User do
    use Ecto.Model
    schema "users" do
      field :name, :string
      field :admin, :boolean
    end
  end

  defmodule Article do
    use Ecto.Model
    schema "articles" do
      field :title, :string
      belongs_to :author, User
    end
  end

  defmodule Comment do
    use Ecto.Model
    schema "comments" do
      field :body, :string
      belongs_to :article, Article
      belongs_to :user, User
    end
  end

  defmodule EctoFactories do
    use ExMachina.Ecto, repo: TestRepo

    factory :user do
      %User{
        name: "John Doe",
        admin: false
      }
    end

    factory :user_map do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    factory :article do
      %Article{
        title: "My Awesome Article",
        author_id: assoc(:author, factory: :user).id
      }
    end

    factory :comment do
      %Comment{
        body: "Great article!",
        article_id: assoc(:article).id,
        user_id: assoc(:user).id
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

  test "fields_for/2 removes Ecto specific fields" do
    assert EctoFactories.fields_for(:user) == %{
      id: nil,
      name: "John Doe",
      admin: false
    }
  end

  test "fields_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      EctoFactories.fields_for(:user_map)
    end
  end

  test "save_record/1 inserts the record into @repo" do
    model = EctoFactories.save_record(%User{name: "John"})

    new_user = TestRepo.one!(User)
    assert model == new_user
  end

  test "assoc/3 returns the passed in key if it exists" do
    existing_account = %{id: 1, plan_type: "free"}
    attrs = %{account: existing_account}

    assert ExMachina.Ecto.assoc(EctoFactories, attrs, :account) == existing_account
  end

  test "assoc/3 does not insert a record if it exists" do
    existing_account = %{id: 1, plan_type: "free"}
    attrs = %{account: existing_account}

    ExMachina.Ecto.assoc(EctoFactories, attrs, :account)

    TestRepo.all(User) == []
  end

  test "assoc/3 creates and returns a factory if one was not in attrs" do
    attrs = %{}

    user = ExMachina.Ecto.assoc(EctoFactories, attrs, :user)

    newly_created_user = TestRepo.one!(User)
    assert newly_created_user.name == "John Doe"
    refute newly_created_user.admin
    assert user == newly_created_user
  end

  test "assoc/3 can specify a factory for the association" do
    attrs = %{}

    account = ExMachina.Ecto.assoc(EctoFactories, attrs, :account, factory: :user)

    new_user = TestRepo.one!(User)
    assert account == new_user
  end

  test "can use assoc/3 in a factory to override associations" do
    my_article = EctoFactories.create(:article, title: "So Deep")

    comment = EctoFactories.create(:comment, article: my_article)

    assert comment.article == my_article
  end
end

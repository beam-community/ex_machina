defmodule ExMachina.EctoTest do
  use ExUnit.Case, async: true

  defmodule TestRepo do
    def insert!(model) do
      # simulate saving of model by adding id
      model = %{model | id: 1}
      send self, {:created, model}
      model
    end
  end

  defmodule MyApp.Book do
    use Ecto.Model
    schema "books" do
      field :title, :string
      belongs_to :publisher, MyApp.Publisher
    end
  end

  defmodule MyApp.Publisher do
    use Ecto.Model
    schema "publishers" do
      field :title, :string
    end
  end

  defmodule MyApp.User do
    use Ecto.Model
    schema "users" do
      field :name, :string
      field :admin, :boolean
    end
  end

  defmodule MyApp.Article do
    use Ecto.Model
    schema "articles" do
      field :title, :string
      belongs_to :author, MyApp.User
      has_many :comments, MyApp.Comment
    end
  end

  defmodule MyApp.Comment do
    use Ecto.Model
    schema "comments" do
      field :body, :string
      belongs_to :article, MyApp.Article
    end
  end

  defmodule MyApp.EctoFactories do
    use ExMachina.Ecto, repo: TestRepo

    factory :book do
      %MyApp.Book{
        title: "Foo",
        publisher_id: 1
      }
    end

    factory :user do
      %MyApp.User{
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
      %MyApp.Article{
        title: "My Awesome Article",
        author_id: assoc(:author, factory: :user).id
      }
    end

    factory :comment do
      %MyApp.Comment{
        body: "This is great!",
        article_id: assoc(:article).id
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
      defmodule MyApp.EctoWithNoRepo do
        use ExMachina.Ecto
      end
    end
  end

  test "fields_for/2 removes Ecto specific fields" do
    assert MyApp.EctoFactories.fields_for(:book) == %{
      id: nil,
      title: "Foo",
      publisher_id: 1
    }
  end

  test "fields_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      MyApp.EctoFactories.fields_for(:user_map)
    end
  end

  test "save_record/1 passes the model to @repo.insert!" do
    model = MyApp.EctoFactories.save_record(%MyApp.User{name: "John"})

    assert_received {:created, %{name: "John"}}
    assert model == %MyApp.User{id: 1, name: "John"}
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

    newly_created_user = %MyApp.User{id: 1, name: "John Doe", admin: false}
    assert user == newly_created_user
    assert_received {:created, ^newly_created_user}
  end

  test "assoc/3 can specify a factory for the association" do
    attrs = %{}

    account = ExMachina.Ecto.assoc(MyApp.EctoFactories, attrs, :account, factory: :user)

    newly_created_account = %MyApp.User{id: 1, name: "John Doe", admin: false}
    assert account == newly_created_account
    assert_received {:created, ^newly_created_account}
  end

  test "can use assoc/3 in a factory to override associations" do
    my_article = MyApp.EctoFactories.create(:article, title: "So Deep")

    comment = MyApp.EctoFactories.create(:comment, article: my_article)

    assert comment.article == my_article
  end
end

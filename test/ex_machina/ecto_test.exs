defmodule ExMachina.EctoTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule User do
    use Ecto.Model
    schema "users" do
      field :name, :string
      field :admin, :boolean
      has_many :comments, ExMachina.EctoTest.Comment
    end
  end

  defmodule CompanyAccount do
    use Ecto.Model
    schema "company_accounts" do
      field :name, :string
      belongs_to :user, User, foreign_key: :manager_id
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

  defmodule Factory do
    use ExMachina.Ecto, repo: TestRepo

    def factory(:user) do
      %User{
        name: "John Doe",
        admin: false
      }
    end

    def factory(:commenting_user) do
      %User{
        name: "John Doe",
        admin: false,
        comments: [build(:comment)]
      }
    end

    def factory(:user_map) do
      %{
        id: 3,
        name: "John Doe",
        admin: false
      }
    end

    def factory(:article) do
      %Article{
        title: "My Awesome Article",
        author: build(:user)
      }
    end

    def factory(:comment) do
      %Comment{
        body: "Great article!",
        article: build(:article),
        user: build(:user)
      }
    end

    def factory(:company_account) do
      %CompanyAccount{
        name: "BigBizAccount",
        user: build(:user)
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
    assert Factory.fields_for(:user) == %{
      id: nil,
      name: "John Doe",
      admin: false
    }
  end

  test "save_record/1 works with irregular foreign_keys for belongs_to associations" do
    company_account = Factory.create(:company_account)
    assert company_account.user.name == "John Doe"
  end

  test "fields_for/2 raises when passed a map" do
    assert_raise ArgumentError, fn ->
      Factory.fields_for(:user_map)
    end
  end

  test "save_record/1 inserts the record into @repo" do
    model = Factory.save_record(%User{name: "John"})

    new_user = TestRepo.one!(User)
    assert model == new_user
  end

  test "save_record/1 saves associated records and sets the association and association id" do
    author = Factory.build(:user)
    article = Factory.save_record(%Article{title: "Ecto is Awesome", author: author})

    assert article.author == TestRepo.one(User)
    assert article.author_id == 1
    assert article.title == "Ecto is Awesome"
    assert TestRepo.get_by(Article, title: "Ecto is Awesome", author_id: 1)
    assert TestRepo.one(User)
  end

  test "save_record/1 assigns the id of already saved records" do
    author = Factory.create(:user)
    article = Factory.save_record(%Article{title: "Ecto is Awesome", author: author})

    assert article.author_id == author.id
    assert article.title == "Ecto is Awesome"
    assert TestRepo.get_by(Article, title: "Ecto is Awesome", author_id: author.id)
    assert TestRepo.one(User)
  end

  test "save_record/1 ignores associations that are not set" do
    Factory.save_record(
      %Article{title: "Ecto is Awesome", author: %Ecto.Association.NotLoaded{}}
    )

    assert TestRepo.get_by(Article, title: "Ecto is Awesome")
    assert TestRepo.all(User) == []
  end

  test "save_record/1 raises for associated records that are not Ecto structs" do
    author = %{}

    message = "expected :author to be an Ecto struct but got %{}"

    assert_raise ArgumentError, message, fn ->
      Factory.save_record(%Article{title: "Ecto is Awesome", author: author})
    end
  end

  test "save_record/1 raises if a map is passed" do
    message = "%{foo: \"bar\"} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      Factory.save_record(%{foo: "bar"})
    end
  end

  test "save_record/1 raises if a non-Ecto struct is passed" do
    message = "%{__struct__: Foo.Bar} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      Factory.save_record(%{__struct__: Foo.Bar})
    end
  end


  test "passed in attrs can override associations" do
    my_article = Factory.create(:article, title: "So Deep")

    comment = Factory.create(:comment, article: my_article)

    assert comment.article == my_article
  end

  test "chaining build and create" do
    Factory.build(:article, title: "Ecto is Awesome") |> Factory.create

    article = TestRepo.get_by!(Article, title: "Ecto is Awesome")
    assert article.author_id
  end

  test "create user with comments" do
    import Ecto.Query

    Factory.create(:commenting_user)

    assert 1 == User |> select([u], count(u.id)) |> TestRepo.one
    assert 1 == Comment |> select([c], count(c.id)) |> TestRepo.one
    assert 1 == Article |> select([a], count(a.id)) |> TestRepo.one
  end
end

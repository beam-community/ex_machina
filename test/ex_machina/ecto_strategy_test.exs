defmodule ExMachina.EctoStrategyTest do
  use ExMachina.EctoCase
  alias ExMachina.TestRepo

  defmodule User do
    use Ecto.Schema
    schema "users" do
      field :name, :string
      field :admin, :boolean
    end
  end

  defmodule Article do
    use Ecto.Schema
    schema "articles" do
      field :title, :string
      belongs_to :author, User
    end
  end

  defmodule Factory do
    use ExMachina
    use ExMachina.EctoStrategy, repo: TestRepo

    def user_factory do
      %User{
        name: "John Doe",
        admin: false
      }
    end

    def article_factory do
      %Article{
        title: "My Awesome Article",
        author: build(:user)
      }
    end
  end

  defmodule FactoryWithNoRepo do
    use ExMachina.EctoStrategy

    def whatever_factory do
      %{}
    end
  end

  test "raises helpful error message if no repo is provided" do
    assert_raise RuntimeError, ~r/expected :repo to be given/, fn ->
      FactoryWithNoRepo.insert(:whatever)
    end
  end

  test "insert/1 inserts the record into the repo" do
    model = Factory.insert(%User{name: "John"})

    new_user = TestRepo.first!(User)
    assert model == new_user
  end

  test "insert/1 raises if a map is passed" do
    message = "%{foo: \"bar\"} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      Factory.insert(%{foo: "bar"})
    end
  end

  test "insert/1 raises if a non-Ecto struct is passed" do
    message = "%{__struct__: Foo.Bar} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      Factory.insert(%{__struct__: Foo.Bar})
    end
  end

  test "passed in attrs can override associations" do
    my_user = Factory.insert(:user, name: "Jane")

    article = Factory.insert(:article, author: my_user)

    assert article.author == my_user
  end
end

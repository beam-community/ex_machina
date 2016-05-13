defmodule ExMachina.EctoStrategyTest do
  use ExMachina.EctoCase

  alias ExMachina.TestFactory
  alias ExMachina.User

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
    model = TestFactory.insert(%User{name: "John"})

    new_user = ExMachina.TestRepo.first!(User)
    assert model == new_user
  end

  test "insert/1 raises if a map is passed" do
    message = "%{foo: \"bar\"} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      TestFactory.insert(%{foo: "bar"})
    end
  end

  test "insert/1 raises if a non-Ecto struct is passed" do
    message = "%{__struct__: Foo.Bar} is not an Ecto model. Use `build` instead"
    assert_raise ArgumentError, message, fn ->
      TestFactory.insert(%{__struct__: Foo.Bar})
    end
  end

  test "passed in attrs can override associations" do
    my_user = TestFactory.insert(:user, name: "Jane")

    article = TestFactory.insert(:article, author: my_user)

    assert article.author == my_user
  end

  test "lazy attributes can be used to assign associations to the same record" do
    article = TestFactory.insert(:article_for_site)
    assert article.author.site == article.site
  end

  test "lazy associations can be overriden by passed in attributes" do
    site = TestFactory.insert(:site)
    article = TestFactory.insert(:article_for_site, site: site)
    assert article.site == site
    assert article.author.site == site
  end

  test "insert/1 raises if attempting to insert already inserted record" do
    message = ~r/You called `insert` on a record that has already been inserted./
    assert_raise RuntimeError, message, fn ->
      TestFactory.insert(:user, name: "Maximus") |> TestFactory.insert
    end
  end
end

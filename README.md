# ExMachina

ExMachina makes it easy to create test data and associations. It works great with
Ecto, but is configurable to work with any persistence library.

## Installation

In `mix.exs`, add the ExMachina dependency:

```elixir
def deps do
  [{:ex_machina, "~> 0.2"}]
end
```

Add `:ex_machina` to your application list:

```elixir
def application do
  [applications: app_list(Mix.env)]
end

defp app_list(:test), do: [:ex_machina | app_list]
defp app_list(_),  do: app_list
defp app_list,  do: [:logger]
```

## Using with Ecto

```elixir
# test/factories.ex
defmodule MyApp.Factories do
  # MyApp.Repo is an Ecto Repo.
  # It will automatically be used when calling `create`
  use ExMachina.Ecto, repo: MyApp.Repo

  factory :config do
    # Factories can be plain maps
    %{url: "http://example.com"}
  end

  factory :article do
    %Article{
      title: "My Awesome Article"
    }
  end

  factory :comment do
    %Comment{
      body: "This is great!",
      author_email: sequence(:email, &"email-#{&1}@example.com"),
      article_id: assoc(:article).id
    }
  end
end
```

Then use it in your tests. This is an example with Phoenix.

```elixir
defmodule MyApp.MyModuleTest do
  use MyApp.ConnCase
  # You can also import this in your MyApp.ConnCase if using Phoenix
  import MyApp.Factories

  test "shows comments for an article" do
    conn = conn()
    article = create(:article)
    comment = create(:comment, article: article)

    conn = get conn, article_path(conn, :show, article.id)

    assert html_response(conn, 200) =~ article.title
    assert html_response(conn, 200) =~ comment.body
  end
end
```

## Using without Ecto

You can use ExMachina without Ecto, by using just the `build` function, or by
defining `save_function/1` in your module.

```elixir
defmodule MyApp.JsonFactories do
  use ExMachina

  factory :user do
    %User{name: "John"}
  end

  def save_function(record) do
    # Poison is a library for working with JSON
    Poison.encode!(record)
  end
end

# Will build and then return a JSON encoded version of the map
MyApp.JsonFactories.create(:user)
```

You can do something similar while also using Ecto by defining a new function.
This gives you the power to call `create` and save to Ecto, or call `build_json`
or `create_json` to return encoded JSON objects.

```elixir
defmodule MyApp.Factories do
  use ExMachina.Ecto, repo: MyApp.Repo

  factory :user do
    %User{name: "John"}
  end

  # builds the object and then encodes it as JSON
  def build_json(factory_name, attrs) do
    build(factory_name, attrs) |> Poison.encode!
  end

  # builds the object, saves it to Ecto and then encodes it
  def create_json(factory_name, attrs) do
    create(factory_name, attrs) |> Poison.encode!
  end
end
```

## License

ExMachina is Copyright © 2015 thoughtbot. It is free software, and may be
redistributed under the terms specified in the [LICENSE](/LICENSE) file.

## About thoughtbot

![thoughtbot](https://thoughtbot.com/logo.png)

ExMachina is maintained and funded by thoughtbot, inc.
The names and logos for thoughtbot are trademarks of thoughtbot, inc.

We love open source software!
See [our other projects][community] or
[hire us][hire] to design, develop, and grow your product.

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com?utm_source=github

## Inspiration

* [Fixtures for Ecto](http://blog.danielberkompas.com/elixir/2015/07/16/fixtures-for-ecto.html)
* [Factory Girl](https://github.com/thoughtbot/factory_girl)

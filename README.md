# ExMachina

[![Circle CI](https://circleci.com/gh/thoughtbot/ex_machina.svg?style=svg&circle-token=fea4685d4951936734e764796c4b37c3686cdab3)](https://circleci.com/gh/thoughtbot/ex_machina)

ExMachina makes it easy to create test data and associations. It works great
with Ecto, but is configurable to work with any persistence library.

## Installation

In `mix.exs`, add the ExMachina dependency:

```elixir
def deps do
  [{:ex_machina, "~> 0.4"}]
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

## Cheatsheet

Check out [the docs](http://hexdocs.pm/ex_machina/ExMachina.html) for more details.

Define factories:

```elixir
defmodule MyApp.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: MyApp.Repo

  # without Ecto
  use ExMachina

  def factory(:user, _attrs) do
    %User{
      name: "Jane Smith",
      email: sequence(:email, &"email-#{&1}@example.com")
    }
  end

  def factory(:article, attrs) do
    %Article{
      title: "Use ExMachina!",
      # has_many/has_one associations are inserted when you call `create`
      comments: [build(:comment)],
      # only available in ExMachina.Ecto
      author: assoc(attrs, :author, factory: :user)
    }
  end

  def factory(:comment, attrs) do
    %Comment{
      text: "It's great!",
      article: assoc(attrs, :article)
    }
  end
end
```

Use factories:

```elixir
# `build*` returns an unsaved comment.
# Associated records defined on the factory are built.
attrs = %{body: "A comment!"} # attrs is optional. Also accepts a keyword list.
build(:comment, attrs)
build_pair(:comment, attrs)
build_list(3, :comment, attrs)

# `create*` returns a saved comment.
# Associated records defined on the factory are built and saved.
create(:comment, attrs)
create_pair(:comment, attrs)
create_list(3, :comment, attrs)

# `fields_for` returns a plain map without any Ecto specific attributes.
# This is only available when using `ExMachina.Ecto`.
fields_for(:comment, attrs)
```

# Flexible Factories with Pipes

```elixir
def make_admin(user) do
  %{user | admin: true}
end

def with_article(user) do
  create(:article, user: user)
  user
end

build(:user) |> make_admin |> create |> with_article
```

## Using with Phoenix and Ecto

There is nothing special you need to do with Phoenix unless you decide to
`import` your factory module.

By default Phoenix imports `Ecto.Model` in the generated `ConnCase` and
`ModelCase`  modules (found in `test/support/conn_case.ex` and
`test/support/model_case.ex`). To import your factory we recommend excluding
`build/2` or aliasing your factory instead.

```elixir
# in test/support/conn_case|model_case.ex

# Add `except: [build: 2] to the `Ecto.Model` import
import Ecto.Model, except: [build: 2]
```

## Usage in a test

```elixir
defmodule MyApp.MyModuleTest do
  use MyApp.ConnCase
  # You can also import this in your MyApp.ConnCase if using Phoenix
  import MyApp.Factory

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
defining `save_record/1` in your module.

```elixir
defmodule MyApp.JsonFactory do
  use ExMachina

  def factory(:user, _attrs) do
    %User{name: "John"}
  end

  def save_record(record) do
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
defmodule MyApp.Factory do
  use ExMachina.Ecto, repo: MyApp.Repo

  def factory(:user, _attrs) do
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

## Contributing

Before opening a pull request, please open an issue first.

    $ git clone https://github.com/thoughtbot/ex_machina.git
    $ cd ex_machina
    $ mix deps.get
    $ mix test

Once you've made your additions and `mix test` passes, go ahead and open a PR!

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

# ExMachina

ExMachina makes it easy to create test data and associations. It works great with
Ecto, but is configurable to work with any persistence library.

## Installation

In `mix.exs`, add the ExMachina dependency:

```elixir
def deps do
  [{:ex_machina, "~> 0.1"}]
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

## Examples

```elixir
defmodule MyApp.ExMachina do
  use ExMachina

  def factory(:config) do
    # Factories can be plain maps
    %{url: "http://example.com"}
  end

  def factory(:article) do
    %Article{
      title: "My Awesome Article"
    }
  end

  def factory(:comment, opts) do
    %Comment{
      body: "This is great!",
      article_id: assoc(opts, :article).id
    }
  end

  def create_record(map) do
    # This example uses Ecto to save records
    MyApp.Repo.insert!(map)
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

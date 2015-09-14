# Anvil

Anvil makes it easy to create test data and associations. It works great with
Ecto, but is configurable to work with any persistence library.

## Installation

In `mix.exs`, add the Anvil dependency:

```elixir
def deps do
  [{:anvil, "~> 0.1"}]
end
```

Add `:anvil` to your application list:

```elixir
def application do
  [applications: app_list(Mix.env)]
end

defp app_list(:test), do: [:anvil | app_list]
defp app_list(_),  do: app_list
defp app_list,  do: [:logger]
```

## Examples

```elixir
defmodule MyApp.Anvil do
  use Anvil

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

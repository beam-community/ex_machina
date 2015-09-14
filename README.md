# Anvil

Anvil makes it easy to create test data and associations. It works great with
Ecto, but is configurable to work with any persistence library.

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

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
    assert_raise RuntimeError, ~r/is not available unless you provide the :repo option/, fn ->
      FactoryWithNoRepo.insert(:whatever)
    end
  end

  test "insert/1 inserts the record into the repo" do
    model = TestFactory.insert(%User{name: "John"})

    new_user = ExMachina.TestRepo.one!(User)

    assert model.id
    assert model.name == new_user.name
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

  test "insert/1 casts all values" do
    model = TestFactory.insert(:user, net_worth: 300)

    assert model.net_worth == Decimal.new(300)
  end

  test "insert/1 casts belongs_to associations" do
    built_author = TestFactory.build(:user, net_worth: 300)
    model = TestFactory.insert(:article, author: built_author)

    assert model.author.net_worth == Decimal.new(300)
  end

  test "insert/1 casts has_many associations" do
    built_article = TestFactory.build(:article, visits: 10, author: nil)
    model = TestFactory.insert(:user, articles: [built_article])

    assert List.first(model.articles).visits == Decimal.new(10)
  end

  test "insert/1 casts embedded associations" do
    author = %ExMachina.Author{name: "Paul", salary: 10.3}
    link = %ExMachina.Link{url: "wow", rating: 4.5}

    comment =
      TestFactory.insert(:comment_with_embedded_assocs,
        author: author,
        links: [link]
      )

    assert comment.author.name == author.name
    assert comment.author.salary == Decimal.from_float(author.salary)
    assert List.first(comment.links).url == link.url
    assert List.first(comment.links).rating == Decimal.from_float(link.rating)
  end

  test "insert/1 ignores virtual fields" do
    user = TestFactory.insert(:user, password: "foo")

    assert user.id != nil
  end

  test "insert/1 sets nil values" do
    model = TestFactory.insert(:article, author: nil)

    assert model.author == nil
  end

  test "insert/1 casts bare maps" do
    model = TestFactory.insert(:article, author: %{net_worth: 300})

    assert model.author.net_worth == Decimal.new(300)
  end

  test "insert/1 casts lists of bare maps" do
    model = TestFactory.insert(:article, comments: [%{author: %{name: "John Doe", salary: 300}}])

    assert hd(model.comments).author.salary == Decimal.new(300)
  end

  test "insert/1 casts bare maps for embeds" do
    model = TestFactory.insert(:comment_with_embedded_assocs, author: %{salary: 300})

    assert model.author.salary == Decimal.new(300)
  end

  test "insert/1 casts lists of bare maps for embeds" do
    model =
      TestFactory.insert(:comment_with_embedded_assocs,
        links: [%{url: "http://thoughtbot.com", rating: 5}]
      )

    assert hd(model.links).rating == Decimal.new(5)
  end

  test "insert/1 casts associations recursively" do
    editor = TestFactory.build(:user, net_worth: 300)
    article = TestFactory.build(:article, editor: editor, author: nil)
    author = TestFactory.insert(:user, articles: [article])

    assert List.first(author.articles).editor.net_worth == Decimal.new(300)
  end

  test "insert/1 assigns params that aren't in the schema" do
    publisher_assoc = ExMachina.Article.__schema__(:association, :publisher)
    publisher_struct = publisher_assoc.related
    publisher_fields = publisher_struct.__schema__(:fields)

    refute Enum.member?(publisher_fields, :name)

    publisher = :publisher |> TestFactory.build() |> Map.merge(%{name: "name"})
    model = TestFactory.insert(:article, publisher: publisher)

    assert model.publisher.name == "name"
  end

  test "passed in attrs can override associations" do
    my_user = TestFactory.insert(:user, name: "Jane")

    article = TestFactory.insert(:article, author: my_user)

    assert article.author == my_user
  end

  test "insert/3 allows options to be passed to the repo" do
    with_args = TestFactory.insert(:user, [name: "Jane"], returning: true)
    assert with_args.id
    assert with_args.name == "Jane"
    assert with_args.db_value

    without_args = TestFactory.insert(:user, [], returning: true)
    assert without_args.id
    assert without_args.db_value

    with_struct = :user |> TestFactory.build() |> TestFactory.insert(returning: true)
    assert with_struct.id
    assert with_struct.db_value

    without_opts = :user |> TestFactory.build() |> TestFactory.insert()
    assert without_opts.id
    refute without_opts.db_value
  end

  test "insert_pair/3 allows options to be passed to the repo" do
    [with_args | _] = TestFactory.insert_pair(:user, [name: "Jane"], returning: true)
    assert with_args.id
    assert with_args.name == "Jane"
    assert with_args.db_value

    [without_args | _] = TestFactory.insert_pair(:user, [], returning: true)
    assert without_args.id
    assert without_args.db_value
  end

  test "insert_list/4 allows options to be passed to the repo" do
    [with_args | _] = TestFactory.insert_list(2, :user, [name: "Jane"], returning: true)
    assert with_args.id
    assert with_args.name == "Jane"
    assert with_args.db_value

    [without_args | _] = TestFactory.insert_list(2, :user, [], returning: true)
    assert without_args.id
    assert without_args.db_value
  end

  test "insert/1 raises a friendly error when casting invalid types" do
    message = ~r/Failed to cast `:invalid` of type ExMachina.InvalidType/

    assert_raise RuntimeError, message, fn ->
      TestFactory.insert(:invalid_cast, invalid: :invalid)
    end
  end

  test "insert/1 raises if attempting to insert already inserted record" do
    message = ~r/You called `insert` on a record that has already been inserted./

    assert_raise RuntimeError, message, fn ->
      :user |> TestFactory.insert(name: "Maximus") |> TestFactory.insert()
    end
  end

  # Regression tests for https://github.com/beam-community/ex_machina/issues/516
  test "insert/1 works with PolymorphicEmbed fields" do
    # This should not raise the PolymorphicEmbed error
    document = TestFactory.insert(:document)

    assert document.id
    assert document.title == "Test Document"
    assert document.content.body == "Sample text content"
  end

  test "insert/1 works with nil PolymorphicEmbed fields" do
    document = TestFactory.insert(:document, content: nil)

    assert document.id
    assert document.content == nil
  end

  test "insert/1 works with polymorphic_embeds_many fields" do
    attachments = [
      %ExMachina.TextContent{body: "attached text"},
      %ExMachina.ImageContent{url: "https://example.com/attached.jpg"}
    ]

    document = TestFactory.insert(:document, attachments: attachments)

    assert document.id
    assert [%ExMachina.TextContent{}, %ExMachina.ImageContent{}] = document.attachments
  end

  test "insert/1 works with empty polymorphic_embeds_many fields" do
    document = TestFactory.insert(:document, attachments: [])

    assert document.id
    assert document.attachments == []
  end

  test "insert/1 persists PolymorphicEmbed fields readable from the database" do
    attachments = [%ExMachina.ImageContent{url: "https://example.com/a.jpg"}]

    document = TestFactory.insert(:document, attachments: attachments)
    reloaded = ExMachina.TestRepo.get!(ExMachina.Document, document.id)

    assert %ExMachina.TextContent{body: "Sample text content"} = reloaded.content
    assert [%ExMachina.ImageContent{url: "https://example.com/a.jpg"}] = reloaded.attachments
  end

  test "insert/3 with repo options works with PolymorphicEmbed fields" do
    document =
      TestFactory.insert(:document, [content: %ExMachina.TextContent{body: "opt"}], returning: true)

    assert document.id
    assert document.content.body == "opt"
  end

  test "insert/1 works with already-built records holding PolymorphicEmbed fields" do
    document =
      TestFactory.insert(%ExMachina.Document{
        title: "Prebuilt",
        content: %ExMachina.TextContent{body: "prebuilt body"}
      })

    assert document.id
    assert document.content.body == "prebuilt body"
  end

  test "insert_list/3 works with PolymorphicEmbed fields" do
    [document | _] = TestFactory.insert_list(3, :document)

    assert document.content.body == "Sample text content"
  end

  test "insert/1 casts PolymorphicEmbed fields reached through has_many associations" do
    user = TestFactory.insert(:user, documents: [TestFactory.build(:document)])

    document = ExMachina.TestRepo.get_by!(ExMachina.Document, author_id: user.id)
    assert %ExMachina.TextContent{body: "Sample text content"} = document.content
  end

  test "insert/1 casts PolymorphicEmbed fields nested in regular embeds" do
    metadata = %ExMachina.DocumentMetadata{
      source: "cms",
      banner: %ExMachina.ImageContent{url: "https://example.com/banner.jpg"}
    }

    document = TestFactory.insert(:document, metadata: metadata)
    reloaded = ExMachina.TestRepo.get!(ExMachina.Document, document.id)

    assert reloaded.metadata.source == "cms"
    assert %ExMachina.ImageContent{url: "https://example.com/banner.jpg"} = reloaded.metadata.banner
  end

  test "build/1 leaves PolymorphicEmbed fields as structs" do
    document = TestFactory.build(:document)

    assert %ExMachina.TextContent{body: "Sample text content"} = document.content
  end

  test "insert/1 raises when a PolymorphicEmbed value with an autogenerated id was never casted" do
    assert_raise RuntimeError, ~r/not able to add an autogenerated key/, fn ->
      TestFactory.insert(:document, content: %ExMachina.NoteContent{note: "hi"})
    end
  end

  test "insert/1 still raises on PolymorphicEmbed fields holding plain maps" do
    assert_raise RuntimeError, ~r/must not be casted/, fn ->
      TestFactory.insert(:document, content: %{body: "not a struct"})
    end
  end

  test "insert/1 still casts Ecto.Enum fields" do
    assert TestFactory.insert(:document, status: :draft).status == :draft
    assert TestFactory.insert(:document, status: "published").status == :published
    assert TestFactory.insert(:document, status: nil).status == nil
  end

  test "insert/1 still raises on invalid Ecto.Enum values" do
    assert_raise RuntimeError, ~r/Failed to cast `:bogus`/, fn ->
      TestFactory.insert(:document, status: :bogus)
    end
  end

  test "insert/1 still casts arrays of Ecto.Enum fields" do
    assert TestFactory.insert(:document, labels: [:internal]).labels == [:internal]
    assert TestFactory.insert(:document, labels: ["public"]).labels == [:public]
  end

  test "insert/1 works with multiple PolymorphicEmbed types" do
    # Test with a different polymorphic type
    document = TestFactory.insert(:document_with_image)

    assert document.id
    assert document.title == "Image Document"
    assert document.content.url == "https://example.com/image.jpg"
  end

  test "insert/1 allows overriding PolymorphicEmbed fields" do
    custom_content = %ExMachina.VideoContent{
      url: "https://example.com/video.mp4",
      duration: 120
    }

    document = TestFactory.insert(:document, content: custom_content)

    assert document.id
    assert document.content.url == "https://example.com/video.mp4"
    assert document.content.duration == 120
  end
end

defmodule ExMachina.EctoTest do
  use ExMachina.EctoCase

  alias ExMachina.Article
  alias ExMachina.Publisher
  alias ExMachina.TestFactory
  alias ExMachina.User

  describe "when the :repo option is not provided" do
    defmodule NoRepoTestFactory do
      use ExMachina.Ecto

      def user_factory do
        %ExMachina.User{
          name: "John Doe",
          admin: false
        }
      end
    end

    test "insert, insert_pair and insert_list raise helpful error messages if no repo was provided" do
      message = """
      insert/1 is not available unless you provide the :repo option. Example:

      use ExMachina.Ecto, repo: MyApp.Repo
      """

      assert_raise RuntimeError, message, fn ->
        NoRepoTestFactory.insert(:user)
      end

      assert_raise RuntimeError, message, fn ->
        NoRepoTestFactory.insert_pair(:user)
      end

      assert_raise RuntimeError, message, fn ->
        NoRepoTestFactory.insert_list(3, :user)
      end
    end

    test "params_for/1 works without a repo" do
      user_params = NoRepoTestFactory.params_for(:user)

      assert user_params == %{name: "John Doe", admin: false}
    end

    test "string_params_for/1 works without a repo" do
      user_params = NoRepoTestFactory.string_params_for(:user)

      assert user_params == %{"name" => "John Doe", "admin" => false}
    end
  end

  describe "insert/2 insert_pair/2 insert_list/3" do
    test "insert, insert_pair and insert_list inserts records" do
      assert %User{} = TestFactory.build(:user) |> TestFactory.insert()
      assert %User{} = TestFactory.insert(:user)
      assert %User{} = TestFactory.insert(:user, admin: true)

      assert [%User{}, %User{}] = TestFactory.insert_pair(:user)
      assert [%User{}, %User{}] = TestFactory.insert_pair(:user, admin: true)

      assert [%User{}, %User{}, %User{}] = TestFactory.insert_list(3, :user)
      assert [%User{}, %User{}, %User{}] = TestFactory.insert_list(3, :user, admin: true)
    end

    test "insert_list/3 handles the number 0" do
      assert [] = TestFactory.insert_list(0, :user)
    end

    test "lazy records get evaluated with insert/2 and insert_* functions" do
      assert %Article{publisher: %Publisher{}} =
               TestFactory.insert(:article, publisher: fn -> TestFactory.build(:publisher) end)

      [%Article{publisher: publisher1}, %Article{publisher: publisher2}] =
        TestFactory.insert_pair(:article, publisher: fn -> TestFactory.build(:publisher) end)

      assert publisher1 != publisher2

      [publisher1, publisher2, publisher3] =
        TestFactory.insert_list(3, :article, publisher: fn -> TestFactory.build(:publisher) end)

      assert publisher1.author != publisher2.author
      assert publisher2.author != publisher3.author
      assert publisher3.author != publisher1.author
    end
  end

  describe "params_for/2" do
    test "params_for/2 removes Ecto specific fields" do
      assert TestFactory.params_for(:user) == %{
               name: "John Doe",
               admin: false,
               articles: []
             }
    end

    test "params_for/2 leaves ids that are not auto-generated" do
      assert TestFactory.params_for(:custom) == %{
               non_autogenerated_id: 1,
               name: "Testing"
             }
    end

    test "params_for/2 removes fields with nil values" do
      assert TestFactory.params_for(:user, admin: nil) == %{
               name: "John Doe",
               articles: []
             }
    end

    test "params_for/2 keeps foreign keys for persisted belongs_to associations" do
      editor = TestFactory.insert(:user)

      article_params =
        TestFactory.params_for(
          :article,
          title: "foo",
          editor: editor
        )

      assert article_params == %{
               title: "foo",
               editor_id: editor.id
             }
    end

    test "params_for/2 deletes unpersisted belongs_to associations" do
      article_params =
        TestFactory.params_for(
          :article,
          title: "foo",
          editor: TestFactory.build(:user)
        )

      assert article_params == %{
               title: "foo"
             }
    end

    test "params_for/2 recursively deletes unpersisted belongs_to associations" do
      article = TestFactory.build(:article, editor: TestFactory.build(:user))

      user_params = TestFactory.params_for(:user, articles: [article])

      assert user_params[:articles] == [
               %{
                 title: article.title
               }
             ]
    end

    test "params_for/2 converts has_one associations to params" do
      article = TestFactory.build(:article)

      user_params = TestFactory.params_for(:user, best_article: article)

      assert user_params[:best_article] == %{title: article.title}
    end

    test "params_for/2 works with has_many associations containing maps" do
      article = %{title: "Foobar"}

      user_params = TestFactory.params_for(:user, articles: [article])

      assert user_params.articles == [%{title: article.title}]
    end

    test "params_for/2 converts embeds_one into a map" do
      author = %ExMachina.Author{name: "Author", salary: 1.0}
      comment_params = TestFactory.params_for(:comment_with_embedded_assocs, author: author)
      assert comment_params.author == %{name: "Author", salary: 1.0}
    end

    test "params_for/2 accepts maps for embeds" do
      author = %{name: "Author", salary: 1.0}
      comment_params = TestFactory.params_for(:comment_with_embedded_assocs, author: author)
      assert comment_params.author == %{name: "Author", salary: 1.0}
    end

    test "params_for/2 converts embeds_many into a list of maps" do
      links = [
        %ExMachina.Link{url: "https://thoughtbot.com", rating: 5},
        %ExMachina.Link{url: "https://github.com", rating: 4}
      ]

      comment_params = TestFactory.params_for(:comment_with_embedded_assocs, links: links)

      assert comment_params.links == [
               %{url: "https://thoughtbot.com", rating: 5},
               %{url: "https://github.com", rating: 4}
             ]
    end

    test "params_for/2 handles nested embeds" do
      links = [
        %ExMachina.Link{
          url: "https://thoughtbot.com",
          rating: 5,
          metadata: %ExMachina.Metadata{text: "foo"}
        }
      ]

      comment_params = TestFactory.params_for(:comment_with_embedded_assocs, links: links)
      assert List.first(comment_params.links).metadata == %{text: "foo"}
    end
  end

  describe "string_params_for/2" do
    test "string_params_for/2 produces maps similar to ones built with params_for/2, but the keys are strings" do
      assert TestFactory.string_params_for(:user) == %{
               "name" => "John Doe",
               "admin" => false,
               "articles" => []
             }
    end

    test "string_params_for/2 converts structs into maps with strings as keys" do
      net_worth = %Money{amount: 2_000}

      user_params = TestFactory.string_params_for(:user, net_worth: net_worth)

      assert user_params["net_worth"] == %{"amount" => 2_000}
    end

    test "string_params_for/2 converts has_one association into map with strings as keys" do
      article = TestFactory.build(:article)

      user_params = TestFactory.string_params_for(:user, best_article: article)

      assert user_params["best_article"] == %{"title" => article.title}
    end

    test "string_params_for/2 converts has_many associations into a list of maps with strings as keys" do
      article = TestFactory.build(:article, title: "Foo")

      user_params = TestFactory.string_params_for(:user, articles: [article])

      assert user_params["articles"] == [%{"title" => article.title}]
    end

    test "string_params_for/2 converts embeds_one into a map with strings as keys" do
      author = %ExMachina.Author{name: "Author", salary: 1.0}

      comment_params =
        TestFactory.string_params_for(:comment_with_embedded_assocs, author: author)

      assert comment_params["author"] == %{"name" => "Author", "salary" => 1.0}
    end

    test "string_params_for/2 converts embeds_many into a list of maps with strings as keys" do
      links = [
        %ExMachina.Link{url: "https://thoughtbot.com", rating: 5},
        %ExMachina.Link{url: "https://github.com", rating: 4}
      ]

      comment_params = TestFactory.string_params_for(:comment_with_embedded_assocs, links: links)

      assert comment_params["links"] == [
               %{"url" => "https://thoughtbot.com", "rating" => 5},
               %{"url" => "https://github.com", "rating" => 4}
             ]
    end

    test "string_params_for/2 converts map with datetime as expected" do
      published_at = DateTime.utc_now()
      article_params = TestFactory.string_params_for(:article, published_at: published_at)
      assert article_params["published_at"] == published_at
    end

    test "string_params_for/2 converts map with naive datetime as expected" do
      published_at = ~N[2000-01-01 23:00:07]
      article_params = TestFactory.string_params_for(:article, published_at: published_at)
      assert article_params["published_at"] == published_at
    end
  end

  describe "params_with_assocs/2" do
    test "params_with_assocs/2 inserts belongs_tos that are set by the factory" do
      assert has_association_in_schema?(ExMachina.Article, :editor)

      assert TestFactory.params_with_assocs(:article) == %{
               title: "My Awesome Article",
               author_id: ExMachina.TestRepo.one!(User).id
             }
    end

    test "params_with_assocs/2 doesn't insert unloaded assocs" do
      not_loaded = %{__struct__: Ecto.Association.NotLoaded}

      assert TestFactory.params_with_assocs(:article, editor: not_loaded) == %{
               title: "My Awesome Article",
               author_id: ExMachina.TestRepo.one!(User).id
             }
    end

    test "params_with_assocs/2 keeps has_many associations" do
      article = TestFactory.build(:article)

      user_params = TestFactory.params_with_assocs(:user, articles: [article])

      assert user_params.articles == [%{title: article.title}]
    end

    test "params_with_assocs/2 removes fields with nil values" do
      assert has_association_in_schema?(ExMachina.User, :articles)

      assert TestFactory.params_with_assocs(:user, admin: nil) == %{
               name: "John Doe",
               articles: []
             }
    end
  end

  describe "string_params_with_assocs/2" do
    test "string_params_with_assocs/2 behaves like params_with_assocs/2 but the keys of the map are strings" do
      assert has_association_in_schema?(ExMachina.Article, :editor)

      assert TestFactory.string_params_with_assocs(:article) == %{
               "title" => "My Awesome Article",
               "author_id" => ExMachina.TestRepo.one!(User).id
             }
    end
  end

  defp has_association_in_schema?(model, association_name) do
    Enum.member?(model.__schema__(:associations), association_name)
  end
end

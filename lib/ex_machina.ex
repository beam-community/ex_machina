defmodule ExMachina do
  @moduledoc """
  Defines functions for generating data

  In depth examples are in the [README](readme.html)
  """
  use Application

  alias ExMachina.UndefinedFactoryError

  @callback build(factory_name :: atom) :: any
  @callback build(factory_name :: atom, attrs :: keyword | map) :: any
  @callback build_list(number_of_records :: integer, factory_name :: atom) :: list
  @callback build_list(number_of_records :: integer, factory_name :: atom, attrs :: keyword | map) :: list
  @callback build_pair(factory_name :: atom) :: list
  @callback build_pair(factory_name :: atom, attrs :: keyword | map) :: list

  @doc false
  def start(_type, _args) do
    Supervisor.start_link([ExMachina.Sequence],
      strategy: :one_for_one,
      name: __MODULE__.Supervisor
    )
  end

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import ExMachina,
        only: [
          sequence: 1,
          sequence: 2,
          sequence: 3,
          merge_attributes: 2,
          evaluate_lazy_attributes: 1
        ]

      alias ExMachina.UndefinedFactoryError

      def build(factory_name, attrs \\ %{}) do
        ExMachina.build(__MODULE__, factory_name, attrs)
      end

      def build_pair(factory_name, attrs \\ %{}) do
        ExMachina.build_pair(__MODULE__, factory_name, attrs)
      end

      def build_list(number_of_records, factory_name, attrs \\ %{}) do
        ExMachina.build_list(__MODULE__, number_of_records, factory_name, attrs)
      end

      @spec create(any) :: no_return
      def create(_) do
        raise_function_replaced_error("create/1", "insert/1")
      end

      @spec create(any, any) :: no_return
      def create(_, _) do
        raise_function_replaced_error("create/2", "insert/2")
      end

      @spec create_pair(any, any) :: no_return
      def create_pair(_, _) do
        raise_function_replaced_error("create_pair/2", "insert_pair/2")
      end

      @spec create_list(any, any, any) :: no_return
      def create_list(_, _, _) do
        raise_function_replaced_error("create_list/3", "insert_list/3")
      end

      @spec raise_function_replaced_error(String.t(), String.t()) :: no_return
      defp raise_function_replaced_error(old_function, new_function) do
        raise """
        #{old_function} has been removed.

        If you are using ExMachina.Ecto, use #{new_function} instead.

        If you are using ExMachina with a custom `save_record/2`, you now must use ExMachina.Strategy.
        See the ExMachina.Strategy documentation for examples.
        """
      end

      defoverridable create: 1, create: 2, create_pair: 2, create_list: 3
    end
  end

  @doc """
  Shortcut for creating unique string values.

  This is automatically imported into a model factory when you `use ExMachina`.

  This is equivalent to `sequence(name, &"\#{name}\#{&1}")`. If you need to
  customize the returned string, see `sequence/2`.

  Note that sequences keep growing and are *not* reset by ExMachina. Most of the
  time you won't need to reset the sequence, but when you do need to reset them,
  you can use `ExMachina.Sequence.reset/0`.

  ## Examples

      def user_factory do
        %User{
          # Will generate "username0" then "username1", etc.
          username: sequence("username")
        }
      end

      def article_factory do
        %Article{
          # Will generate "Article Title0" then "Article Title1", etc.
          title: sequence("Article Title")
        }
      end
  """
  @spec sequence(String.t()) :: String.t()

  def sequence(name), do: ExMachina.Sequence.next(name)

  @doc """
  Create sequences for generating unique values.

  This is automatically imported into a model factory when you `use ExMachina`.

  The `name` can be any term, although it is typically an atom describing the
  sequence. Each time a sequence is called with the same `name`, its number is
  incremented by one.

  The `formatter` function takes the sequence number, and returns a sequential
  representation of that number – typically a formatted string.

  ## Examples

      def user_factory do
        %{
          # Will generate "me-0@foo.com" then "me-1@foo.com", etc.
          email: sequence(:email, &"me-\#{&1}@foo.com"),
          # Will generate "admin" then "user", "other", "admin" etc.
          role: sequence(:role, ["admin", "user", "other"])
        }
      end
  """
  @spec sequence(any, (integer -> any) | nonempty_list) :: any
  def sequence(name, formatter), do: ExMachina.Sequence.next(name, formatter)

  @doc """
  Similar to `sequence/2` but it allows for passing a `start_at` option
  to the sequence generation.

  ## Examples

      def user_factory do
        %{
          # Will generate "me-100@foo.com" then "me-101@foo.com", etc.
          email: sequence(:email, &"me-\#{&1}@foo.com", start_at: 100),
        }
      end
  """
  @spec sequence(any, (integer -> any) | nonempty_list, start_at: non_neg_integer) :: any
  def sequence(name, formatter, opts), do: ExMachina.Sequence.next(name, formatter, opts)

  @doc """
  Builds a single factory.

  This will defer to the `[factory_name]_factory/0` callback defined in the
  factory module in which it is `use`d.

  ### Example

      def user_factory do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: false}
      build(:user)

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)

  ## Full control of a factory's attributes

  If you want full control over the factory attributes, you can define the
  factory with `[factory_name]_factory/1`, taking in the attributes as the first
  argument.

  Caveats:

  - ExMachina will no longer merge the attributes for your factory. If you want
  to do that, you can merge the attributes with the `merge_attributes/2` helper.

  - ExMachina will no longer evaluate lazy attributes. If you want to do that,
  you can evaluate the lazy attributes with the `evaluate_lazy_attributes/1`
  helper.

  ### Example

      def article_factory(attrs) do
        title = Map.get(attrs, :title, "default title")
        slug = Article.title_to_slug(title)

        article = %Article{title: title, slug: slug}

        article
        # merge attributes on your own
        |> merge_attributes(attrs)
        # evaluate any lazy attributes
        |> evaluate_lazy_attributes()
      end

      # Returns %Article{title: "default title", slug: "default-title"}
      build(:article)

      # Returns %Article{title: "hello world", slug: "hello-world"}
      build(:article, title: "hello world")
  """
  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})

    function_name = build_function_name(factory_name)

    cond do
      factory_accepting_attributes_defined?(module, function_name) ->
        apply(module, function_name, [attrs])

      factory_without_attributes_defined?(module, function_name) ->
        module
        |> apply(function_name, [])
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()

      true ->
        raise UndefinedFactoryError, factory_name
    end
  end

  defp build_function_name(factory_name) do
    factory_name
    |> Atom.to_string()
    |> Kernel.<>("_factory")
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    |> String.to_atom()
  end

  defp factory_accepting_attributes_defined?(module, function_name) do
    Code.ensure_loaded?(module) && function_exported?(module, function_name, 1)
  end

  defp factory_without_attributes_defined?(module, function_name) do
    Code.ensure_loaded?(module) && function_exported?(module, function_name, 0)
  end

  @doc """
  Helper function to merge attributes into a factory that could be either a map
  or a struct.

  ## Example

      # custom factory
      def article_factory(attrs) do
        title = Map.get(attrs, :title, "default title")

        article = %Article{
          title: title
        }

        merge_attributes(article, attrs)
      end

  Note that when trying to merge attributes into a struct, this function will
  raise if one of the attributes is not defined in the struct.
  """
  @spec merge_attributes(struct | map, map) :: struct | map | no_return
  def merge_attributes(%{__struct__: _} = record, attrs), do: struct!(record, attrs)
  def merge_attributes(record, attrs), do: Map.merge(record, attrs)

  @doc """
  Helper function to evaluate lazy attributes that are passed into a factory.

  ## Example

      # custom factory
      def article_factory(attrs) do
        %{title: "title"}
        |> merge_attributes(attrs)
        |> evaluate_lazy_attributes()
      end

      def author_factory do
        %{name: sequence("gandalf")}
      end

      # => returns [
      #  %{title: "title", author: %{name: "gandalf0"},
      #  %{title: "title", author: %{name: "gandalf0"}
      # ]
      build_pair(:article, author: build(:author))

      # => returns [
      #  %{title: "title", author: %{name: "gandalf0"},
      #  %{title: "title", author: %{name: "gandalf1"}
      # ]
      build_pair(:article, author: fn -> build(:author) end)
  """
  @spec evaluate_lazy_attributes(struct | map) :: struct | map
  def evaluate_lazy_attributes(%{__struct__: record} = factory) do
    struct!(
      record,
      factory |> Map.from_struct() |> do_evaluate_lazy_attributes(factory)
    )
  end

  def evaluate_lazy_attributes(attrs) when is_map(attrs) do
    do_evaluate_lazy_attributes(attrs, attrs)
  end

  defp do_evaluate_lazy_attributes(attrs, parent_factory) do
    attrs
    |> Enum.map(fn
      {k, v} when is_function(v, 1) -> {k, v.(parent_factory)}
      {k, v} when is_function(v) -> {k, v.()}
      {_, _} = tuple -> tuple
    end)
    |> Enum.into(%{})
  end

  @doc """
  Builds two factories.

  This is just an alias for `build_list(2, factory_name, attrs)`.

  ## Example

      # Returns a list of 2 users
      build_pair(:user)
  """
  def build_pair(module, factory_name, attrs \\ %{}) do
    ExMachina.build_list(module, 2, factory_name, attrs)
  end

  @doc """
  Builds any number of factories.

  ## Example

      # Returns a list of 3 users
      build_list(3, :user)
  """
  def build_list(module, number_of_records, factory_name, attrs \\ %{}) do
    stream =
      Stream.repeatedly(fn ->
        ExMachina.build(module, factory_name, attrs)
      end)

    Enum.take(stream, number_of_records)
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc "Raises a helpful error if no factory is defined."
      @spec factory(any) :: no_return
      def factory(factory_name), do: raise(UndefinedFactoryError, factory_name)
    end
  end
end

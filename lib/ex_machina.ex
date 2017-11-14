defmodule ExMachina do
  @moduledoc """
  Defines functions for generating data

  In depth examples are in the [README](readme.html)
  """

  defmodule UndefinedFactoryError do
    @moduledoc """
    Error raised when trying to build or create a factory that is undefined.
    """

    defexception [:message]

    def exception(factory_name) do
      message =
        """
        No factory defined for #{inspect factory_name}.

        Please check for typos or define your factory:

            def #{factory_name}_factory do
              ...
            end
        """
      %UndefinedFactoryError{message: message}
    end
  end

  use Application

  @doc false
  def start(_type, _args), do: ExMachina.Sequence.start_link

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import ExMachina, only: [sequence: 1, sequence: 2]

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

      @spec raise_function_replaced_error(String.t, String.t) :: no_return
      defp raise_function_replaced_error(old_function, new_function) do
        raise """
        #{old_function} has been removed.

        If you are using ExMachina.Ecto, use #{new_function} instead.

        If you are using ExMachina with a custom `save_record/2`, you now must use ExMachina.Strategy.
        See the ExMachina.Strategy documentation for examples.
        """
      end

      defoverridable [create: 1, create: 2, create_pair: 2, create_list: 3]
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
  @spec sequence(String.t) :: String.t

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

  @spec sequence(any, (integer -> any)) :: any
  def sequence(name, formatter), do: ExMachina.Sequence.next(name, formatter)

  @doc """
  Builds a single factory.

  This will defer to the `[factory_name]_factory/0` callback defined in the
  factory module in which it is `use`d.

  ## Example

      def user_factory do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)
  """
  @callback build(factory_name :: atom, attrs :: keyword | map) :: any

  @doc false
  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    function_name = build_function_name(factory_name)
    if Code.ensure_loaded?(module) && function_exported?(module, function_name, 0) do
      apply(module, function_name, []) |> do_merge(attrs)
    else
      raise UndefinedFactoryError, factory_name
    end
  end

  defp build_function_name(factory_name) do
    factory_name
    |> Atom.to_string
    |> Kernel.<>("_factory")
    |> String.to_atom
  end

  defp do_merge(%{__struct__: _} = record, attrs), do: struct!(record, attrs)
  defp do_merge(record, attrs), do: Map.merge(record, attrs)

  @doc """
  Builds two factories.

  This is just an alias for `build_list(2, factory_name, attrs)`.

  ## Example

      # Returns a list of 2 users
      build_pair(:user)
  """
  @callback build_pair(factory_name :: atom, attrs :: keyword | map) :: list

  @doc false
  def build_pair(module, factory_name, attrs \\ %{}) do
    ExMachina.build_list(module, 2, factory_name, attrs)
  end

  @doc """
  Builds any number of factories.

  ## Example

      # Returns a list of 3 users
      build_list(3, :user)
  """
  @callback build_list(number_of_records :: integer, factory_name :: atom, attrs :: keyword | map) :: list

  @doc false
  def build_list(module, number_of_records, factory_name, attrs \\ %{}) do
    Stream.repeatedly(fn ->
      ExMachina.build(module, factory_name, attrs)
    end)
    |> Enum.take(number_of_records)
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc "Raises a helpful error if no factory is defined."
      @spec factory(any) :: no_return
      def factory(factory_name), do: raise UndefinedFactoryError, factory_name
    end
  end
end

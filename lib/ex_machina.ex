defmodule ExMachina do
  @moduledoc """
  Defines functions for generating data

  In depth examples are in the [README](README.html)
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

      def build_list(number_of_factories, factory_name, attrs \\ %{}) do
        ExMachina.build_list(__MODULE__, number_of_factories, factory_name, attrs)
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
  Shortcut for creating unique string values. Similar to sequence/2

  If you need to customize the returned string, see `ExMachina.sequence/2`.

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
  def sequence(name), do: ExMachina.Sequence.next(name)

  @doc """
  Create sequences for generating unique values

  ## Examples

      def user_factory do
        %{
          # Will generate "me-0@example.com" then "me-1@example.com", etc.
          email: sequence(:email, &"me-\#{&1}@foo.com")
        }
      end
  """
  def sequence(name, formatter), do: ExMachina.Sequence.next(name, formatter)

  @doc """
  Builds a factory with the passed in factory_name and attrs

  ## Example

      def user_factory do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)
  """
  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    function_name = Atom.to_string(factory_name) <> "_factory" |> String.to_atom
    if Code.ensure_loaded?(module) && function_exported?(module, function_name, 0) do
      apply(module, function_name, []) |> do_merge(attrs)
    else
      raise UndefinedFactoryError, factory_name
    end
  end

  defp do_merge(%{__struct__: _} = record, attrs) do
    struct!(record, attrs)
  end
  defp do_merge(record, attrs) do
    Map.merge(record, attrs)
  end

  @doc """
  Builds and returns 2 records with the passed in factory_name and attrs

  ## Example

      # Returns a list of 2 users
      build_pair(:user)
  """
  def build_pair(module, factory_name, attrs \\ %{}) do
    ExMachina.build_list(module, 2, factory_name, attrs)
  end

  @doc """
  Builds and returns X records with the passed in factory_name and attrs

  ## Example

      # Returns a list of 3 users
      build_list(3, :user)
  """
  def build_list(module, number_of_factories, factory_name, attrs \\ %{}) do
    Enum.map(1..number_of_factories, fn(_) ->
      ExMachina.build(module, factory_name, attrs)
    end)
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Raises a helpful error if no factory is defined.
      """
      @spec factory(any) :: no_return
      def factory(factory_name) do
        raise UndefinedFactoryError, factory_name
      end
    end
  end
end

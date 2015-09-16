defmodule ExMachina do
  @moduledoc """
  Defines functions for generating data

  In depth examples are in the [README](README.html)
  """

  defmodule UndefinedFactory do
    @moduledoc """
    Error raised when trying to build or create a factory that is undefined.
    """

    defexception [:message]

    def exception(factory_name) do
      message = "No factory defined for #{inspect factory_name}"
      %UndefinedFactory{message: message}
    end
  end

  defmodule UndefinedSave do
    @moduledoc """
    Error raised when trying to call create and save_record/1 is
    not defined.
    """

    defexception [:message]

    def exception do
      %UndefinedSave{
        message: "Define save_record/1. See docs for ExMachina.save_record/1."
      }
    end
  end

  use Application

  def start(_type, _args), do: ExMachina.Sequence.start_link

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)

      import ExMachina, only: [sequence: 2]

      def build(factory_name, attrs \\ %{}) do
        ExMachina.build(__MODULE__, factory_name, attrs)
      end

      def create(factory_name, attrs \\ %{}) do
        ExMachina.create(__MODULE__, factory_name, attrs)
      end

      def create_pair(factory_name, attrs \\ %{}) do
        ExMachina.create_pair(__MODULE__, factory_name, attrs)
      end

      def create_list(number_of_factories, factory_name, attrs \\ %{}) do
        ExMachina.create_list(__MODULE__, number_of_factories, factory_name, attrs)
      end
    end
  end

  @doc """
  Create sequences for generating unique values

  ## Examples

      def factory(:user) do
        %{
          # Will generate "me-0@example.com" then "me-1@example.com", etc.
          email: sequence(:email, &"me-\#{&1}@foo.com")
        }
      end
  """
  def sequence(name, formatter), do: ExMachina.Sequence.next(name, formatter)

  @doc """
  Builds a factory with the passed in factory_name

  ## Example

      def factory(:user) do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)
  """
  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    module.factory(factory_name, attrs) |> Map.merge(attrs)
  end

  @doc """
  Builds and saves a factory with the passed in factory_name

  If using ExMachina.Ecto it will use the Ecto Repo passed in to save the
  record automatically.

  If you are not using ExMachina.Ecto, you need to define a `save_record/1`
  function in your module. See `save_record` docs for more information.

  ## Example

      def factory(:user) do
        %{name: "John Doe", admin: false}
      end

      # Saves and returns %{name: "John Doe", admin: true}
      create(:user, admin: true)
  """
  def create(module, factory_name, attrs \\ %{}) do
    ExMachina.build(module, factory_name, attrs) |> module.save_record
  end

  @doc """
  Creates and returns 2 records with the passed in factory_name and attrs

  ## Example

      # Returns a list of 2 users
      create_pair(:user)
  """
  def create_pair(module, factory_name, attrs \\ %{}) do
    ExMachina.create_list(module, 2, factory_name, attrs)
  end

  @doc """
  Creates and returns X records with the passed in factory_name and attrs

  ## Example

      # Returns a list of 3 users
      create_pair(3, :user)
  """
  def create_list(module, number_of_factories, factory_name, attrs \\ %{}) do
    Enum.map(1..number_of_factories, fn(_) ->
      ExMachina.create(module, factory_name, attrs)
    end)
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Calls factory/1 with the passed in factory name

      This allows you to define factories without the `attrs` param.
      """
      def factory(factory_name, _attrs) do
        __MODULE__.factory(factory_name)
      end

      @doc """
      Raises a helpful error if no factory is defined.
      """
      def factory(factory_name) do
        raise UndefinedFactory, factory_name
      end

      @doc """
      Saves a record when `create` is called. Uses Ecto if using ExMachina.Ecto

      If using ExMachina.Ecto (`use ExMachina.Ecto, repo: MyApp.Repo`) this
      function will call `insert!` on the passed in repo.

      If you are not using ExMachina.Ecto, you must define a custom
      save_record/1 for saving the record.

      ## Examples

          defmodule MyApp.Factories do
            use ExMachina.Ecto, repo: MyApp.Repo

            def factory(:user), do: %User{name: "John"}
          end

          # Will build and save the record to the MyApp.Repo
          MyApp.Factories.create(:user)

          defmodule MyApp.JsonFactories do
            # Note, we are not using ExMachina.Ecto
            use ExMachina

            def factory(:user), do: %User{name: "John"}

            def save_function(record) do
              # Poison is a library for working with JSON
              Poison.encode!(record)
            end
          end

          # Will build and then return a JSON encoded version of the map
          MyApp.JsonFactories.create(:user)
      """
      def save_record(record) do
        raise UndefinedSave
      end
    end
  end
end

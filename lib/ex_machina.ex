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

    def exception(module: module, factory_name: factory_name) do
      message = "No factory defined for #{inspect factory_name}. Define a #{module}.#{factory_name}/1 function"
      %UndefinedFactory{message: message}
    end
  end

  defmodule UndefinedSave do
    @moduledoc """
    Error raised when trying to call create and no repo or save_function is
    defined.
    """

    defexception [:message]

    def exception do
      %UndefinedSave{
        message: "Define save_function/1 or include the repo option. See docs
        for ExMachina.save_record."
      }
    end
  end

  use Application

  def start(_type, _args), do: ExMachina.Sequence.start_link

  defmacro __using__(opts) do
    quote do
      @before_compile unquote(__MODULE__)
      @repo Dict.get(unquote(opts), :repo)

      import ExMachina, only: [sequence: 2]

      defp assoc(attrs, factory_name, opts \\ []) do
        ExMachina.assoc(__MODULE__, attrs, factory_name, opts)
      end

      def fields_for(factory_name, attrs \\ %{}) do
        ExMachina.fields_for(__MODULE__, factory_name, attrs)
      end

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

      def save_record(record) do
        ExMachina.save_record(__MODULE__, @repo, record)
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
  Gets a factory from the passed in attrs, or creates if none is present

  ## Examples

      attrs = %{user: %{name: "Someone"}}
      # Returns attrs.user
      assoc(attrs, :user)

      attrs = %{}
      # Creates and returns new instance based on :user factory
      assoc(attrs, :user)

      attrs = %{}
      # Creates and returns new instance based on :user factory
      assoc(attrs, :author, factory: :user)
  """
  def assoc(module, attrs, factory_name, opts \\ []) do
    case Map.get(attrs, factory_name) do
      nil -> create_assoc(module, factory_name, opts)
      record -> record
    end
  end

  defp create_assoc(module, _factory_name, factory: factory_name) do
    ExMachina.create(module, factory_name)
  end
  defp create_assoc(module, factory_name, _opts) do
    ExMachina.create(module, factory_name)
  end

  @doc """
  Builds a factory with the passed in factory_name and returns its fields

  This is only for use with Ecto models.

  Will return a map with the fields and virtual fields, but without the Ecto
  metadata and associations.

  ## Example

      def factory(:user) do
        %MyApp.User{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      fields_for(:user, admin: true)
  """
  def fields_for(module, factory_name, attrs \\ %{}) do
    module.build(factory_name, attrs)
    |> drop_ecto_fields
  end

  defp drop_ecto_fields(record = %{__struct__: struct, __meta__: %{__struct__: Ecto.Schema.Metadata}}) do
    record
    |> Map.from_struct
    |> Map.delete(:__meta__)
    |> Map.drop(struct.__schema__(:associations))
  end
  defp drop_ecto_fields(record) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead."
  end

  @doc """
  Builds a factory with the passed in factory_name

  Raises ExMachina.UndefinedFactory error if the factory function is undefined.

  ## Example

      def factory(:user) do
        %{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      build(:user, admin: true)
  """
  def build(module, factory_name, attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    if function_exported?(module, factory_name, 1) do
      apply(module, factory_name, [attrs]) |> Map.merge(attrs)
    else
      raise UndefinedFactory, module: module, factory_name: factory_name
    end
  end

  @doc """
  Builds and saves a factory with the passed in factory_name

  If you pass in repo when using ExMachina it will use the Ecto Repo to save the
  record automatically. If you do not pass the repo, you need to define a
  `save_record/1` function in your module. See `save_record` docs for more
  information.

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
  Saves a record when `create` is called. Uses Ecto if the `repo` option is set

  If you include the `repo` option (`use ExMachina, repo: MyApp.Repo`) this
  function will call `insert!` on the passed in repo.

  If you do not pass in the `repo` option, you must define a custom
  save_function/1 for saving the record.

  ## Examples

      defmodule MyApp.Factories do
        use ExMachina, repo: MyApp.Repo

        def factory(:user), do: %User{name: "John"}
      end

      # Will build and save the record to the MyApp.Repo
      MyApp.Factories.create(:user)

      defmodule MyApp.JsonFactories do
        # Note `repo` was not passed as an option
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
  def save_record(module, repo, record) do
    if repo do
      repo.insert!(record)
    else
      module.save_function(record)
    end
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
      Raises a helpful error if `create` is called and no save_function is
      defined.
      """
      def save_function(record) do
        raise UndefinedSave
      end
    end
  end
end

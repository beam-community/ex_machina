defmodule ExMachina.Ecto do
  defmacro __using__(opts) do
    quote do
      use ExMachina

      @repo Dict.fetch!(unquote(opts), :repo)

      def fields_for(factory_name, attrs \\ %{}) do
        ExMachina.Ecto.fields_for(__MODULE__, factory_name, attrs)
      end

      defp assoc(attrs, factory_name, opts \\ []) do
        ExMachina.Ecto.assoc(__MODULE__, attrs, factory_name, opts)
      end

      def save_record(record) do
        ExMachina.Ecto.save_record(__MODULE__, @repo, record)
      end
    end
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
    assoc_id = "#{factory_name}_id" |> String.to_atom
    if Map.has_key?(attrs, assoc_id) do
      raise ArgumentError, "Set association with :#{factory_name} instead of :#{assoc_id}"
    else
      case Map.get(attrs, factory_name) do
        nil -> create_assoc(module, factory_name, opts)
        record -> record
      end
    end
  end

  defp create_assoc(module, _factory_name, factory: factory_name) do
    ExMachina.create(module, factory_name)
  end
  defp create_assoc(module, factory_name, _opts) do
    ExMachina.create(module, factory_name)
  end

  @doc """
  Saves a record using `Repo.insert!` when `create` is called.
  """
  def save_record(module, repo, record) do
    if repo do
      repo.insert!(record)
    end
  end
end

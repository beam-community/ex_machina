defmodule ExMachina.Ecto do
  defmacro __using__(opts) do
    verify_ecto_dep
    if repo = Keyword.get(opts, :repo) do
      quote do
        use ExMachina

        import ExMachina.Ecto, only: [assoc: 1, assoc: 2]

        @repo unquote(repo)

        def fields_for(factory_name, attrs \\ %{}) do
          ExMachina.Ecto.fields_for(__MODULE__, factory_name, attrs)
        end

        def save_record(record) do
          ExMachina.Ecto.save_record(__MODULE__, @repo, record)
        end
      end
    else
      raise ArgumentError,
        """
        expected :repo to be given as an option. Example:

        use ExMachina.Ecto, repo: MyApp.Repo
        """
    end
  end

  defmacro assoc(factory_name, opts \\ []) do
    quote do
      ExMachina.Ecto.assoc(__MODULE__, var!(attrs), unquote(factory_name), unquote(opts))
    end
  end

  defp verify_ecto_dep do
    unless Code.ensure_loaded?(Ecto) do
      raise "You tried to use ExMachina.Ecto, but the Ecto module is not loaded. " <>
        "Please add ecto to your dependencies."
    end
  end

  @doc """
  Builds a factory with the passed in factory_name and returns its fields

  This is only for use with Ecto models.

  Will return a map with the fields and virtual fields, but without the Ecto
  metadata and associations.

  ## Example

      factory :user do
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
  Gets a factory from the passed in attrs, or builds if none is present

  ## Examples

      attrs = %{user: %{name: "Someone"}}
      # Returns attrs.user
      assoc(:user)

      attrs = %{}
      # Builds and returns new instance based on :user factory
      assoc(:user)

      attrs = %{}
      # Builds and returns new instance based on :user factory
      assoc(:author, factory: :user)
  """
  def assoc(module, attrs, factory_name, opts \\ []) do
    case Map.get(attrs, factory_name) do
      nil -> build_assoc(module, factory_name, opts)
      record -> record
    end
  end

  defp build_assoc(module, _factory_name, factory: factory_name) do
    ExMachina.build(module, factory_name)
  end
  defp build_assoc(module, factory_name, _opts) do
    ExMachina.build(module, factory_name)
  end

  @doc """
  Saves a record and all associated records using `Repo.insert!`
  """
  def save_record(module, repo, record) do
    record
    |> associate_records(module)
    |> repo.insert!
  end

  defp associate_records(built_record = %{__struct__: struct}, module) do
    association_names = struct.__schema__(:associations)

    Enum.reduce association_names, built_record, fn(association_name, record) ->
      case association = Map.get(record, association_name) do
        %{__meta__: %{state: :built}} ->
          association = ExMachina.create(module, association)
          put_assoc(record, association_name, association)
        %{__meta__: %{state: :loaded}} ->
          put_assoc(record, association_name, association)
        %{__struct__: Ecto.Association.NotLoaded} -> record
        _ ->
          raise ArgumentError,
            "expected #{inspect(association_name)} to be an Ecto struct but got #{inspect(association)}"
      end
    end
  end

  defp put_assoc(record, association_name, association) do
    association_id = "#{association_name}_id" |> String.to_atom

    record
    |> Map.put(association_id, association.id)
    |> Map.put(association_name, association)
  end
end

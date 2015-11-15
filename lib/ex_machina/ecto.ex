defmodule ExMachina.Ecto do
  defmacro __using__(opts) do
    verify_ecto_dep
    if repo = Keyword.get(opts, :repo) do
      quote do
        use ExMachina

        @repo unquote(repo)

        def fields_for(factory_name, attrs \\ %{}) do
          ExMachina.Ecto.fields_for(__MODULE__, factory_name, attrs)
        end

        def save_record(record) do
          ExMachina.Ecto.save_record(__MODULE__, @repo, record)
        end

        defp assoc(attrs, factory_name, opts \\ []) do
          ExMachina.Ecto.assoc(__MODULE__, attrs, factory_name, opts)
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

      def factory(:user, _attrs) do
        %MyApp.User{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      fields_for(:user, admin: true)
  """
  def fields_for(module, factory_name, attrs \\ %{}) do
    module.build(factory_name, attrs)
    |> drop_ecto_fields
    |> drop_nil_fields
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

  defp drop_nil_fields(fields) do
    fields
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @doc """
  Gets a factory from the passed in attrs, or builds if none is present

  ## Examples

      attrs = %{user: %{name: "Someone"}}
      # Returns attrs.user
      assoc(attrs, :user)

      attrs = %{}
      # Builds and returns new instance based on :user factory
      assoc(attrs, :user)

      attrs = %{}
      # Builds and returns new instance based on :user factory
      assoc(attrs, :author, factory: :user)
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

  defp get_assocs(%{__struct__: struct}) do
    for a <- struct.__schema__(:associations) do
      {a, struct.__schema__(:association, a)}
    end
  end

  defp belongs_to_assocs(model) do
    for {a, %{__struct__: Ecto.Association.BelongsTo}} <- get_assocs(model), do: a
  end

  defp not_loaded_assocs(model) do
    for {a, %{__struct__: Ecto.Association.Has}} <- get_assocs(model),
      !Ecto.Association.loaded?(Map.get(model, a)),
      do: a
  end

  defp restore_belongs_to_associations(target, source) do
    target
      |> belongs_to_assocs
      |> Enum.reduce(target, fn(a, target) -> Map.put(target, a, Map.get(source, a)) end)
  end

  defp convert_to_changes(record) do
    record
    |> Map.from_struct
    |> Map.delete(:__meta__)
    # drop fields for `belongs_to` assocs as they cannot be handled by changeset
    |> Map.drop(belongs_to_assocs(record))
    |> Map.drop(not_loaded_assocs(record))
  end

  @doc """
  Saves a record and all associated records using `Repo.insert!`

  Before inserting, changes are wrapped in a changeset. This means that
  has_many, has_one, embeds_one, and embeds_many associations will be saved
  correctly. Any belongs_to associations will also be saved.

      # Will save the article and list of comments
      create(:article, comments: [build(:comment)])

  """
  def save_record(module, repo, %{__struct__: model, __meta__: %{__struct__: Ecto.Schema.Metadata}} = record) do
    record = record |> persist_belongs_to_associations(module)
    changes = record |> convert_to_changes

    struct(model)
    |> Ecto.Changeset.change(changes)
    |> repo.insert!
    |> restore_belongs_to_associations(record)
  end
  def save_record(_, _ , record) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end

  defp persist_belongs_to_associations(built_record, module) do
    association_names = belongs_to_assocs(built_record)

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

  defp get_owner_key(record, association_name) do
    record.__struct__.__schema__(:association, association_name).owner_key
  end

  defp put_assoc(record, association_name, association) do
    association_id = get_owner_key(record, association_name)
    record
    |> Map.put(association_id, association.id)
    |> Map.put(association_name, association)
  end
end

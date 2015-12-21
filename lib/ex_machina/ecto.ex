defmodule ExMachina.Ecto do
  defmacro __using__(opts) do
    verify_ecto_dep
    if repo = Keyword.get(opts, :repo) do
      quote do
        @before_compile unquote(__MODULE__)

        use ExMachina

        @repo unquote(repo)

        def fields_for(factory_name, attrs \\ %{}) do
          ExMachina.Ecto.fields_for(__MODULE__, factory_name, attrs)
        end

        def save_record(record) do
          ExMachina.Ecto.save_record(__MODULE__, @repo, record)
        end

        defp assoc(_, factory_name, _ \\ nil) do
          raise """
          assoc/3 has been removed. Please use build instead. Built records will be automatically saved when you call create.

            def factory(#{factory_name}) do
              %{
                ...
                some_assoc: build(:some_assoc)
                ...
              }
            end
          """
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

  defp get_assocs(%{__struct__: struct}) do
    for assoc <- struct.__schema__(:associations) do
      {assoc, struct.__schema__(:association, assoc)}
    end
  end

  defp assoc_keys(record) do
    for {key, _assoc} <- get_assocs(record), do: key
  end

  defp put_assoc_changes(changeset, record, module) do
    keys = assoc_keys(record) -- belongs_to_assoc_keys(record)
    Enum.reduce(keys, changeset, fn(key, changes) ->
      case Map.get(record, key) do
        %{__struct__: Ecto.Association.NotLoaded} ->
          changes
        associations when is_list(associations) ->
          changesets = associations |> Enum.map(&(record_to_changeset(&1, module)))

          Ecto.Changeset.put_assoc(changes, key, changesets)
        association ->
          Ecto.Changeset.put_assoc(changes, key, association)
      end
    end)
  end

  defp belongs_to_assoc_keys(model) do
    for {key, %{__struct__: Ecto.Association.BelongsTo}} <- get_assocs(model), do: key
  end

  defp restore_belongs_to_associations(target, source) do
    Enum.reduce(belongs_to_assoc_keys(target), target, fn(key, target) ->
      Map.put(target, key, Map.get(source, key))
    end)
  end

  defp get_embeds(%{__struct__: struct}) do
    for embed <- struct.__schema__(:embeds) do
      {embed, struct.__schema__(:embed, embed)}
    end
  end

  defp embed_keys(record) do
    for {key, _embed} <- get_embeds(record), do: key
  end

  defp put_embed_changes(changeset, record) do
    Enum.reduce(embed_keys(record), changeset, fn(key, changes) ->
      Ecto.Changeset.put_embed(changes, key, Map.get(record, key))
    end)
  end

  defp convert_to_changes(record) do
    record
    |> Map.from_struct
    |> Map.delete(:__meta__)
    |> Map.drop(assoc_keys(record))
    |> Map.drop(embed_keys(record))
  end

  @doc """
  Saves a record and all associated records using `Repo.insert!`

  Before inserting, changes are wrapped in a changeset. This means that
  has_many, has_one, embeds_one, and embeds_many associations will be saved
  correctly. Any belongs_to associations will also be saved.

      # Will save the article and list of comments
      create(:article, comments: [build(:comment)])

  """
  def save_record(module, repo, %{__meta__: %{__struct__: Ecto.Schema.Metadata}} = record) do
    record = record |> persist_belongs_to_associations(module)

    record
    |> record_to_changeset(module)
    |> repo.insert!
    |> restore_belongs_to_associations(record)
  end
  def save_record(_, _ , record) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end

  defp persist_belongs_to_associations(built_record, module) do
    association_names = belongs_to_assoc_keys(built_record)

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

  defp record_to_changeset(%{__struct__: model, __meta__: %{__struct__: Ecto.Schema.Metadata}} = record, module) do
    changes = record |> convert_to_changes


    struct(model)
    |> module.make_changeset(changes)
    |> put_assoc_changes(record, module)
    |> put_embed_changes(record)
  end

  defmacro __before_compile__(_env) do
    # We are using line -1 because we don't want warnings coming from
    # save_record/1 when someone defines there own save_recod/1 function.
    quote line: -1 do
      @doc """
      Raises a helpful error if no factory is defined.
      """
      def make_changeset(record, changes) do
        Ecto.Changeset.change(record, changes)
      end
    end
  end
end

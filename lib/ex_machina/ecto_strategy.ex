defmodule ExMachina.EctoStrategy do
  @moduledoc false

  use ExMachina.Strategy, function_name: :insert

  def handle_insert(%{__meta__: %{state: :loaded}} = record, _) do
    raise "You called `insert` on a record that has already been inserted.
     Make sure that you have not accidentally called insert twice.

     The record you attempted to insert:

     #{inspect record, limit: :infinity}"
  end

  def handle_insert(%{__meta__: %{__struct__: Ecto.Schema.Metadata}} = record, %{repo: repo}) do
    record
    |> cast(nil)
    |> repo.insert!
  end

  def handle_insert(record, %{repo: _repo}) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end

  def handle_insert(_record, _opts) do
    raise "expected :repo to be given to ExMachina.EctoStrategy"
  end

  defp cast(record, field_set_by_parent) do
    parent_assoc = assoc_set_by_parent(record, field_set_by_parent)

    record
    |> cast_all_fields
    |> skip_already_set_assoc(parent_assoc)
    |> cast_all_assocs(nil)
  end

  defp assoc_set_by_parent(%{__struct__: schema}, field_set_by_parent) do
    if field_set_by_parent do
      schema.__schema__(:associations)
      |> Enum.find(fn(assoc) ->
        foreign_key =
          :association
          |> schema.__schema__(assoc)
          |> Map.get(:owner_key, nil)
        foreign_key == field_set_by_parent end)
    end
  end

  defp skip_already_set_assoc(record, parent_assoc) do
    Map.delete(record, parent_assoc)
  end

  defp cast_all_fields(struct) do
    struct
    |> ExMachina.Ecto.drop_ecto_fields
    |> Map.keys
    |> cast_all_fields(struct)
  end

  defp cast_all_fields(fields, struct) do
    Enum.reduce(fields, struct, fn(field, struct) ->
      casted_value = cast_field(field, struct)
      Map.put(struct, field, casted_value)
    end)
  end

  defp cast_field(field, %{__struct__: schema} = struct) do
    field_type = schema.__schema__(:type, field)
    virtual_field? = !field_type
    embed_type = schema.__schema__(:embed, field)
    embedded_field? = !!embed_type

    value = Map.get(struct, field)

    if virtual_field? || embedded_field? do
      value
    else
      cast_value(field_type, value, struct)
    end
  end

  defp cast_value(field_type, value, struct) do
    case Ecto.Type.cast(field_type, value) do
      {:ok, value} ->
        value
      _ ->
        raise "Failed to cast `#{inspect value}` of type #{inspect field_type} in #{inspect struct}."
    end
  end

  defp cast_all_assocs(%{__struct__: schema} = struct, field_set_by_parent) do
    assocs = get_schema_assocs(schema)

    Enum.reduce(assocs, struct, fn(assoc, struct) ->
      casted_value = struct |> Map.get(assoc) |> cast_assoc(assoc, struct, field_set_by_parent)

      Map.put(struct, assoc, casted_value)
    end)
  end

  defp cast_assoc(original_assoc, assoc_key, %{__struct__: schema} = struct, field_set_by_parent) do
    case original_assoc do
      has_or_embeds_many when is_list(has_or_embeds_many) ->
        Enum.map(has_or_embeds_many,
          &(cast_assoc(&1, assoc_key, struct, foreign_key(schema, assoc_key))))

      %{__struct__: Ecto.Association.NotLoaded} ->
        original_assoc

      %{__struct__: _} ->
        cast(original_assoc, field_set_by_parent)

      %{} ->
        schema
        |> assoc_type(assoc_key)
        |> struct()
        |> Map.merge(original_assoc)
        |> cast(field_set_by_parent)

      nil -> nil
    end
  end

  defp foreign_key(schema, assoc_key) do
    assoc_reflection = schema.__schema__(:association, assoc_key)
    if assoc_reflection do
      assoc_reflection.related_key
    end
  end

  defp assoc_type(schema, assoc_key) do
    assoc_reflection = schema.__schema__(:association, assoc_key) || schema.__schema__(:embed, assoc_key)
    assoc_reflection.related
  end

  defp get_schema_assocs(schema) do
    schema.__schema__(:associations) ++ schema.__schema__(:embeds)
  end
end

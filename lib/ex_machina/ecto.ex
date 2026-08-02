defmodule ExMachina.Ecto do
  @moduledoc """
  Module for building and inserting factories with Ecto

  This module works much like the regular `ExMachina` module, but adds a few
  nice things that make working with Ecto easier.

  * It uses `ExMachina.EctoStrategy`, which adds `insert/1`, `insert/2`,
  `insert/3` `insert_pair/2`, `insert_list/3`.
  * Adds a `params_for` function that is useful for working with changesets or
    sending params to API endpoints.

  More in-depth examples are in the [README](readme.html).
  """

  @callback insert(factory_name :: atom) :: any
  @callback insert(factory_name :: atom, attrs :: keyword | map) :: any

  @doc """
  Builds a factory and inserts it into the database.

  The first two arguments are the same as `c:ExMachina.build/2`. The last
  argument is a set of options that will be passed to Ecto's
  [`Repo.insert!/2`](https://hexdocs.pm/ecto/Ecto.Repo.html#c:insert!/2).

  ## Examples

      # return all values from the database
      insert(:user, [name: "Jane"], returning: true)
      build(:user, name: "Jane") |> insert(returning: true)

      # use a different prefix
      insert(:user, [name: "Jane"], prefix: "other_tenant")
      build(:user, name: "Jane") |> insert(prefix: "other_tenant")
  """
  @callback insert(factory_name :: atom, attrs :: keyword | map, opts :: keyword | map) :: any

  @doc """
  Builds two factories and inserts them into the database.

  The arguments are the same as `c:ExMachina.build_pair/2`.
  """
  @callback insert_pair(factory_name :: atom) :: list
  @callback insert_pair(factory_name :: atom, attrs :: keyword | map) :: list

  @doc """
  Builds many factories and inserts them into the database.

  The arguments are the same as `c:ExMachina.build_list/3`.
  """
  @callback insert_list(number_of_records :: integer, factory_name :: atom) :: list
  @callback insert_list(
              number_of_records :: integer,
              factory_name :: atom,
              attrs :: keyword | map
            ) :: list

  @doc """
  Builds a factory and returns only its fields.

  This is only for use with Ecto models.

  Will return a map with the fields and virtual fields, but without the Ecto
  metadata, the primary key, or any `belongs_to` associations. This will
  recursively act on `has_one` associations and Ecto structs found in
  `has_many` associations.

  If you want `belongs_to` associations to be inserted, use
  `c:params_with_assocs/2`.

  If you want params with string keys use `c:string_params_for/2`.

  ## Example

      def user_factory do
        %MyApp.User{name: "John Doe", admin: false}
      end

      # Returns %{name: "John Doe", admin: true}
      params_for(:user, admin: true)

      # Returns %{name: "John Doe", admin: false}
      params_for(:user)
  """
  @callback params_for(factory_name :: atom) :: %{optional(atom) => any}
  @callback params_for(factory_name :: atom, attrs :: keyword | map) :: %{optional(atom) => any}

  @doc """
  Similar to `c:params_for/2` but converts atom keys to strings in returned map.

  The result of this function can be safely used in controller tests for Phoenix
  web applications.

  ## Example

      def user_factory do
        %MyApp.User{name: "John Doe", admin: false}
      end

      # Returns %{"name" => "John Doe", "admin" => true}
      string_params_for(:user, admin: true)
  """
  @callback string_params_for(factory_name :: atom) :: %{optional(String.t()) => any}
  @callback string_params_for(factory_name :: atom, attrs :: keyword | map) :: %{
              optional(String.t()) => any
            }

  @doc """
  Similar to `c:params_for/2` but inserts all `belongs_to` associations and
  sets the foreign keys.

  If you want params with string keys use `c:string_params_with_assocs/2`.

  ## Example

      def article_factory do
        %MyApp.Article{title: "An Awesome Article", author: build(:author)}
      end

      # Inserts an author and returns %{title: "An Awesome Article", author_id: 12}
      params_with_assocs(:article)
  """
  @callback params_with_assocs(factory_name :: atom) :: %{optional(atom) => any}
  @callback params_with_assocs(factory_name :: atom, attrs :: keyword | map) :: %{
              optional(atom) => any
            }
  @doc """
  Similar to `c:params_with_assocs/2` but converts atom keys to strings in
  returned map.

  The result of this function can be safely used in controller tests for Phoenix
  web applications.

  ## Example

      def article_factory do
        %MyApp.Article{title: "An Awesome Article", author: build(:author)}
      end

      # Inserts an author and returns %{"title" => "An Awesome Article", "author_id" => 12}
      string_params_with_assocs(:article)
  """
  @callback string_params_with_assocs(factory_name :: atom) :: %{optional(String.t()) => any}
  @callback string_params_with_assocs(factory_name :: atom, attrs :: keyword | map) :: %{
              optional(String.t()) => any
            }

  defmacro __using__(opts) do
    verify_ecto_dep()

    quote do
      use ExMachina
      use ExMachina.EctoStrategy, repo: unquote(Keyword.get(opts, :repo))

      def params_for(factory_name, attrs \\ %{}) do
        ExMachina.Ecto.params_for(__MODULE__, factory_name, attrs)
      end

      def string_params_for(factory_name, attrs \\ %{}) do
        ExMachina.Ecto.string_params_for(__MODULE__, factory_name, attrs)
      end

      def params_with_assocs(factory_name, attrs \\ %{}) do
        ExMachina.Ecto.params_with_assocs(__MODULE__, factory_name, attrs)
      end

      def string_params_with_assocs(factory_name, attrs \\ %{}) do
        ExMachina.Ecto.string_params_with_assocs(__MODULE__, factory_name, attrs)
      end
    end
  end

  @doc false
  def params_for(module, factory_name, attrs \\ %{}) do
    factory_name
    |> module.build(attrs)
    |> recursively_strip
  end

  @doc false
  def string_params_for(module, factory_name, attrs \\ %{}) do
    module
    |> params_for(factory_name, attrs)
    |> convert_atom_keys_to_strings
  end

  @doc false
  def params_with_assocs(module, factory_name, attrs \\ %{}) do
    factory_name
    |> module.build(attrs)
    |> insert_belongs_to_assocs(module)
    |> recursively_strip
  end

  @doc false
  def string_params_with_assocs(module, factory_name, attrs \\ %{}) do
    module
    |> params_with_assocs(factory_name, attrs)
    |> convert_atom_keys_to_strings
  end

  defp recursively_strip(%{__struct__: _} = record) do
    record
    |> set_persisted_belongs_to_ids
    |> handle_assocs
    |> handle_embeds
    |> handle_parameterized_fields
    |> drop_ecto_fields
    |> drop_fields_with_nil_values
  end

  defp recursively_strip(record), do: record

  # Struct values held by parameterized types (PolymorphicEmbed, ...) are
  # dumped through the type so the params keep the data the type needs to
  # cast them back, such as the polymorphic type discriminator.
  defp handle_parameterized_fields(%{__struct__: schema} = record) do
    fields = schema.__schema__(:fields) -- schema.__schema__(:embeds)

    Enum.reduce(fields, record, &dump_parameterized_field/2)
  end

  defp dump_parameterized_field(field_name, %{__struct__: schema} = record) do
    field_type = schema.__schema__(:type, field_name)
    value = Map.get(record, field_name)

    Map.put(record, field_name, dump_parameterized(field_type, value))
  end

  # The Ecto < 3.12 {:parameterized, module, params} form is intentionally
  # not handled here: Ecto.Type.embedded_dump/3 only accepts the newer
  # two-tuple form (Dialyzer rejects the call as one that can never
  # succeed), so on older Ecto these values keep the previous behavior and
  # pass through unchanged.
  defp dump_parameterized({:parameterized, _} = type, value) when is_struct(value),
    do: embedded_dump(type, value)

  defp dump_parameterized({:array, {:parameterized, _} = type}, values) when is_list(values),
    do: Enum.map(values, &dump_parameterized(type, &1))

  defp dump_parameterized(_field_type, value), do: value

  # Dumping is best-effort: a type that cannot dump a hand-built value,
  # whether by returning an error or by raising (e.g. PolymorphicEmbed
  # refuses to dump an embed whose autogenerated id was never casted),
  # keeps the original value, preserving the previous params behavior.
  # Only the dump call is rescued so bugs in the normalization below
  # surface instead of being silently absorbed by the fallback.
  defp embedded_dump(type, value) do
    case try_embedded_dump(type, value) do
      {:ok, dumped} -> normalize_dumped_dates(dumped)
      _ -> value
    end
  end

  defp try_embedded_dump(type, value) do
    Ecto.Type.embedded_dump(type, value, :json)
  rescue
    _error -> :error
  end

  # Ecto's embedded dump keeps date and time values as structs. When dates
  # are not preserved (see convert_atom_keys_to_strings/1), emit ISO8601
  # strings so the dumped params stay castable and JSON encodable. This
  # means :preserve_dates also affects dumped parameterized values in
  # params_for/2 output, not only the string params variants.
  defp normalize_dumped_dates(%module{} = value)
       when module in [DateTime, NaiveDateTime, Date, Time] do
    if Application.get_env(:ex_machina, :preserve_dates, false) do
      value
    else
      module.to_iso8601(value)
    end
  end

  defp normalize_dumped_dates(%_{} = value), do: value

  defp normalize_dumped_dates(%{} = map),
    do: Map.new(map, fn {key, value} -> {key, normalize_dumped_dates(value)} end)

  defp normalize_dumped_dates(values) when is_list(values),
    do: Enum.map(values, &normalize_dumped_dates/1)

  defp normalize_dumped_dates(value), do: value

  defp handle_assocs(%{__struct__: struct} = record) do
    associations = struct.__schema__(:associations)

    Enum.reduce(associations, record, fn association_name, record ->
      case struct.__schema__(:association, association_name) do
        %{__struct__: Ecto.Association.BelongsTo} ->
          Map.delete(record, association_name)

        _ ->
          record
          |> Map.get(association_name)
          |> handle_assoc(record, association_name)
      end
    end)
  end

  defp handle_assoc(original_assoc, record, association_name) do
    case original_assoc do
      %{__meta__: %{__struct__: Ecto.Schema.Metadata, state: :built}} ->
        assoc = recursively_strip(original_assoc)
        Map.put(record, association_name, assoc)

      nil ->
        Map.put(record, association_name, nil)

      list when is_list(list) ->
        has_many_assoc = Enum.map(original_assoc, &recursively_strip/1)
        Map.put(record, association_name, has_many_assoc)

      %{__struct__: Ecto.Association.NotLoaded} ->
        Map.delete(record, association_name)
    end
  end

  defp handle_embeds(%{__struct__: struct} = record) do
    embeds = struct.__schema__(:embeds)

    Enum.reduce(embeds, record, fn embed_name, record ->
      record
      |> Map.get(embed_name)
      |> handle_embed(record, embed_name)
    end)
  end

  defp handle_embed(original_embed, record, embed_name) do
    case original_embed do
      %{} ->
        embed = recursively_strip(original_embed)
        Map.put(record, embed_name, embed)

      list when is_list(list) ->
        embeds_many = Enum.map(original_embed, &recursively_strip/1)
        Map.put(record, embed_name, embeds_many)

      nil ->
        Map.delete(record, embed_name)
    end
  end

  defp set_persisted_belongs_to_ids(%{__struct__: struct} = record) do
    associations = struct.__schema__(:associations)

    Enum.reduce(associations, record, fn association_name, record ->
      association = struct.__schema__(:association, association_name)

      with %{__struct__: Ecto.Association.BelongsTo} <- association,
           belongs_to <- Map.get(record, association_name),
           %{__meta__: %{__struct__: Ecto.Schema.Metadata, state: :loaded}} <- belongs_to do
        set_belongs_to_primary_key(record, belongs_to, association)
      else
        _ -> record
      end
    end)
  end

  defp set_belongs_to_primary_key(record, belongs_to, association) do
    primary_key = Map.get(belongs_to, association.related_key)
    Map.put(record, association.owner_key, primary_key)
  end

  defp insert_belongs_to_assocs(%{__struct__: struct} = record, module) do
    associations = struct.__schema__(:associations)

    Enum.reduce(associations, record, fn association_name, record ->
      case struct.__schema__(:association, association_name) do
        association = %{__struct__: Ecto.Association.BelongsTo} ->
          insert_built_belongs_to_assoc(module, association, record)

        _ ->
          record
      end
    end)
  end

  defp insert_built_belongs_to_assoc(module, association, record) do
    case Map.get(record, association.field) do
      built_relation = %{__meta__: %{state: :built}} ->
        relation = module.insert(built_relation)
        set_belongs_to_primary_key(record, relation, association)

      _ ->
        Map.delete(record, association.owner_key)
    end
  end

  @doc false
  def drop_ecto_fields(%{__struct__: struct} = record) do
    record
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> drop_autogenerated_ids(struct)
  end

  def drop_ecto_fields(embedded_record), do: embedded_record

  defp drop_autogenerated_ids(map, struct) do
    case struct.__schema__(:autogenerate_id) do
      {name, _source, _type} -> Map.delete(map, name)
      {name, _type} -> Map.delete(map, name)
      nil -> map
    end
  end

  defp drop_fields_with_nil_values(map) do
    map
    |> Enum.reject(fn {_, value} -> value == nil end)
    |> Enum.into(%{})
  end

  defp convert_atom_keys_to_strings(values) when is_list(values) do
    Enum.map(values, &convert_atom_keys_to_strings/1)
  end

  defp convert_atom_keys_to_strings(%NaiveDateTime{} = value) do
    if Application.get_env(:ex_machina, :preserve_dates, false) do
      value
    else
      value |> Map.from_struct() |> convert_atom_keys_to_strings()
    end
  end

  defp convert_atom_keys_to_strings(%DateTime{} = value) do
    if Application.get_env(:ex_machina, :preserve_dates, false) do
      value
    else
      value |> Map.from_struct() |> convert_atom_keys_to_strings()
    end
  end

  defp convert_atom_keys_to_strings(%{__struct__: _} = record) when is_map(record) do
    record |> Map.from_struct() |> convert_atom_keys_to_strings()
  end

  defp convert_atom_keys_to_strings(record) when is_map(record) do
    Enum.reduce(record, Map.new(), fn {key, value}, acc ->
      Map.put(acc, to_string(key), convert_atom_keys_to_strings(value))
    end)
  end

  defp convert_atom_keys_to_strings(value), do: value

  defp verify_ecto_dep do
    unless Code.ensure_loaded?(Ecto) do
      raise "You tried to use ExMachina.Ecto, but the Ecto module is not loaded. " <>
              "Please add ecto to your dependencies."
    end
  end
end

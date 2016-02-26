defmodule ExMachina.Ecto do
  defmacro __using__(opts) do
    verify_ecto_dep
    if repo = Keyword.get(opts, :repo) do
      quote do
        use ExMachina

        @repo unquote(repo)

        def params_for(factory_name, attrs \\ %{}) do
          ExMachina.Ecto.params_for(__MODULE__, factory_name, attrs)
        end

        def fields_for(factory_name, attrs \\ %{}) do
          raise "fields_for/2 has been renamed to params_for/2."
        end

        def save_record(record) do
          ExMachina.Ecto.save_record(@repo, record)
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
      params_for(:user, admin: true)
  """
  def params_for(module, factory_name, attrs \\ %{}) do
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
  Saves a record and all associated records using `Repo.insert!`

  ## Example

      # Will save the article and list of comments
      create(:article, comments: [build(:comment)])
  """
  def save_record(repo, %{__meta__: %{__struct__: Ecto.Schema.Metadata}} = record) do
    repo.insert!(record)
  end
  def save_record(_, record) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end
end

defmodule ExMachina.EctoStrategy do
  @moduledoc false

  use ExMachina.Strategy, function_name: :insert

  def handle_insert(%{__meta__: %{__struct__: Ecto.Schema.Metadata}} = record, %{repo: repo}) do
    repo.insert! record
  end

  def handle_insert(record, %{repo: _repo}) do
    raise ArgumentError, "#{inspect record} is not an Ecto model. Use `build` instead"
  end

  def handle_insert(_record, _opts) do
    raise "expected :repo to be given to ExMachina.EctoStrategy"
  end
end

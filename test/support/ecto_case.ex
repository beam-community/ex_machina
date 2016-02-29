defmodule ExMachina.EctoCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExMachina.TestRepo)
  end
end

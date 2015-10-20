defmodule ExMachina.EctoCase do
  use ExUnit.CaseTemplate
  alias ExMachina.TestRepo

  setup do
    Ecto.Adapters.SQL.restart_test_transaction(TestRepo, [])
    :ok
  end
end

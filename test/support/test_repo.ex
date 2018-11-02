defmodule ExMachina.TestRepo do
  use Ecto.Repo,
    otp_app: :ex_machina,
    adapter: Ecto.Adapters.Postgres
end

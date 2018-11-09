use Mix.Config

config :ex_machina, ExMachina.TestRepo,
  hostname: "localhost",
  database: "ex_machina_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  username: "postgres"

config :logger, level: :warn

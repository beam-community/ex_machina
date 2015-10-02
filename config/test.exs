use Mix.Config

config :ex_machina, ExMachina.TestRepo,
  adapter: Sqlite.Ecto,
  database: ":memory:",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

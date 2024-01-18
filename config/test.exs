import Config

config :ex_machina, preserve_dates: true

config :ex_machina, ExMachina.TestRepo,
  pool: Ecto.Adapters.SQL.Sandbox,
  hostname: "localhost",
  port: "5432",
  username: "postgres",
  password: "postgres",
  database: "ex_machina_test"

config :logger, level: :warning

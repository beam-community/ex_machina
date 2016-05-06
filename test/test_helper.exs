Mix.Task.run "ecto.drop", ["quiet", "-r", "ExMachina.TestRepo"]
Mix.Task.run "ecto.create", ["quiet", "-r", "ExMachina.TestRepo"]
Mix.Task.run "ecto.migrate", ["-r", "ExMachina.TestRepo"]

ExMachina.TestRepo.start_link
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(ExMachina.TestRepo, :manual)

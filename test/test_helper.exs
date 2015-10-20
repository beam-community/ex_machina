ExMachina.TestRepo.start_link
ExUnit.start()

Mix.Task.run "ecto.drop", ["--quiet", "-r", "ExMachina.TestRepo"]
Mix.Task.run "ecto.create", ["--quiet", "-r", "ExMachina.TestRepo"]
Mix.Task.run "ecto.migrate", ["--quiet", "-r", "ExMachina.TestRepo"]
Ecto.Adapters.SQL.begin_test_transaction(ExMachina.TestRepo)

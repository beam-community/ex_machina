# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# By default, ExMachina will convert datetime values to a map with string
# keys such as
# %{ "calendar" => Calendar.ISO, "day" => 4, "hour" => 17, "microsecond" => {657863, 6}, "minute" => 25, "month" => 8, "second" => 42, "std_offset" => 0, "time_zone" => "Etc/UTC", "utc_offset" => 0, "year" => 2019, "zone_abbr" => "UTC" }
# If you would like the date values to be preserved, you can set the following
# config value. This may be made the default in the future but is a breaking change.
#
# config :ex_machina, preserve_dates: true
#
#
# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
if Mix.env() == :test do
  import_config "test.exs"
end

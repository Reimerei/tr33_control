# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :tr33_control,
  ecto_repos: [Tr33Control.Repo],
  command_max_index: 9,
  esp32_ip: "192.168.0.42",
  esp32_port: "1337",
  serial_port: System.get_env("SERIAL_PORT") || "ttyAMA0",
  color_palette: 0

# Configures the endpoint
config :tr33_control, Tr33ControlWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zZr2viMBYqxMGuXda+ebLv+fhZOlOZOWjdNWwaSpCMSeRk59ZWqJA18pZBnevauD",
  render_errors: [view: Tr33ControlWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Tr33Control.PubSub, adapter: Phoenix.PubSub.PG2]

config :tr33_control, Tr33Control.Repo,
  adapter: Sqlite.Ecto2,
  database: "/opt/tr33/tr33_db.sqlite3"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

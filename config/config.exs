# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :tr33_control, Tr33ControlWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OjMmejtWRlJsOaBulT2hTUpx06835YTLQzx3H95MPV2X+M93hXrtJdxKASr/w5Mk",
  render_errors: [view: Tr33ControlWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Tr33Control.PubSub,
  live_view: [signing_salt: "HC+iC2aJ"]

config :tr33_control,
  ecto_repos: [Tr33Control.Repo],
  command_max_index: 9,
  esp32_ip: "192.168.0.42",
  esp32_port: "1337",
  serial_port: System.get_env("SERIAL_PORT") || "ttyAMA0",
  udp_listen_port: 1337,
  cache_persist_dir: System.get_env("CACHE_PERSIST_DIR") || "/root/tr33/cache_persist",
  # led_structure: :keller

  # led_structure: :dode
  led_structure: :tr33

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

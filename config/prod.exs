use Mix.Config

config :tr33_control, Tr33ControlWeb.Endpoint,
  url: [host: "tr33", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

import_config "prod.secret.exs"

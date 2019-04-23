use Mix.Config

config :tr33_control, Tr33ControlWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :tr33_control, Tr33ControlWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/tr33_control_web/views/.*(ex)$},
      ~r{lib/tr33_control_web/templates/.*(eex)$},
      ~r{lib/tr33_control_web/live/.*(ex)$}
    ]
  ]

config :logger, :console, format: "[$level] $time $message\n"

config :phoenix, :stacktrace_depth, 20

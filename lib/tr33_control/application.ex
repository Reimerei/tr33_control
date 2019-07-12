defmodule Tr33Control.Application do
  use Application
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Preset}

  def start(_type, _args) do
    import Supervisor.Spec

    Application.fetch_env!(:tr33_control, :cache_persist_dir)
    |> File.mkdir_p!()

    children = [
      Tr33ControlWeb.Endpoint,
      Tr33Control.Commands.UART,
      Tr33Control.UdpServer,
      worker(Cachex, [Command, []], id: :cachex_commands),
      worker(Cachex, [Event, []], id: :cachex_events),
      worker(Cachex, [Preset, []], id: :cachex_presets),
      Tr33Control.Joystick,
      Tr33Control.Commands.Updater
      # Tr33Control.Commands.Socket
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    sup = Supervisor.start_link(children, opts)

    Commands.init()

    sup
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

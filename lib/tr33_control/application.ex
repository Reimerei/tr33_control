defmodule Tr33Control.Application do
  use Application
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Preset}

  def start(_type, _args) do
    Application.fetch_env!(:tr33_control, :cache_persist_dir)
    |> File.mkdir_p!()

    children = [
      Tr33ControlWeb.Telemetry,
      {Phoenix.PubSub, name: Tr33Control.PubSub},
      Supervisor.child_spec({Cachex, Command}, id: make_ref()),
      Supervisor.child_spec({Cachex, Event}, id: make_ref()),
      Supervisor.child_spec({Cachex, Preset}, id: make_ref()),
      Tr33ControlWeb.Endpoint,
      Tr33Control.Commands.UART,
      Tr33Control.UdpServer,
      Tr33Control.Joystick,
      Tr33Control.Commands.Updater
      # Tr33Control.Commands.Socket
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    sup = {:ok, _} = Supervisor.start_link(children, opts)

    Commands.init()

    sup
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

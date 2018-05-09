defmodule Tr33Control.Application do
  use Application
  alias Tr33Control.Commands

  def start(_type, _args) do
    import Supervisor.Spec

    Commands.Cache.init()

    children = [
      # supervisor(Tr33Control.Repo, []),
      Tr33ControlWeb.Endpoint,
      Tr33Control.Commands.Socket
      # Tr33Control.Commands.Cache
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

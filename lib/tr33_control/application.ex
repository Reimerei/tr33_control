defmodule Tr33Control.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      # supervisor(Tr33Control.Repo, []),
      Tr33Control.Commands.Socket,
      Tr33ControlWeb.Endpoint,
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

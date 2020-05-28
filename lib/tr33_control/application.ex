defmodule Tr33Control.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Tr33ControlWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tr33Control.PubSub},
      # Start the Endpoint (http/https)
      Tr33ControlWeb.Endpoint
      # Start a worker by calling: Tr33Control.Worker.start_link(arg)
      # {Tr33Control.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

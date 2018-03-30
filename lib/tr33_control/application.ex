defmodule Tr33Control.Application do
  use Application
  alias Tr33Control.Commands.Command

  def start(_type, _args) do
    import Supervisor.Spec

    initial_commands()

    children = [
      # supervisor(Tr33Control.Repo, []),
      Tr33Control.Commands.Socket,
      Tr33ControlWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp initial_commands() do
    commands = [
      %Command{index: 0, type: :singe_hue, data: [50]},
      %Command{index: 1, type: :disabled},
      %Command{index: 2, type: :disabled},
      %Command{index: 3, type: :disabled},
      %Command{index: 4, type: :disabled}
    ]

    Application.put_env(:tr33_control, :commands, commands)
  end
end

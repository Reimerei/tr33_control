defmodule Tr33ControlWeb.CommandsController do
  use Tr33ControlWeb, :controller
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @default_commands 0..9 |> Enum.map(fn n -> %Command{index: n} end)

  def show(conn, _params) do
    commands = @default_commands
    types = Command.CommandTypes.__enum_map__()
    render(conn, "form.html", commands: @default_commands, types: types)
  end

  def receive(conn, params) do
    case Commands.create_command(params) do
      {:ok, command} ->
        result = Commands.send_command(command)

        conn
        |> put_status(200)
        |> json(%{result: "#{inspect(result)}"})

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(render_changeset_errors(changeset))
    end
  end

  def render_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

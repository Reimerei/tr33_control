defmodule Tr33ControlWeb.CommandsController do
  use Tr33ControlWeb, :controller
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  def index(conn, _params) do
    render(conn, "index.html")
  end

  # def receive(conn, params) do
  #   case Commands.create_command(params) do
  #     {:ok, command} ->
  #       result = Commands.send_command(command)

  #       conn
  #       |> put_status(200)
  #       |> json(%{result: "#{inspect(result)}"})

  #     {:error, changeset} ->
  #       conn
  #       |> put_status(400)
  #       |> json(render_changeset_errors(changeset))
  #   end
  # end

  # def render_changeset_errors(%Ecto.Changeset{} = changeset) do
  #   Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
  #     Enum.reduce(opts, message, fn {key, value}, acc ->
  #       String.replace(acc, "%{#{key}}", to_string(value))
  #     end)
  #   end)
  # end
end

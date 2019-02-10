defmodule Tr33ControlWeb.DocsController do
  use Tr33ControlWeb, :controller
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  def index(conn, _params) do
    commands =
      Commands.command_types()
      |> Enum.map(&%Command{type: &1})

    conn
    |> render("index.html", commands: commands)
  end
end

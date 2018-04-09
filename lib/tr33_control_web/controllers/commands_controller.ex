defmodule Tr33ControlWeb.CommandsController do
  use Tr33ControlWeb, :controller
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

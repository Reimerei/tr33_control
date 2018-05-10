defmodule Tr33ControlWeb.CommandsController do
  use Tr33ControlWeb, :controller
  require Logger

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end

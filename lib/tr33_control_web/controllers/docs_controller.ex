defmodule Tr33ControlWeb.DocsController do
  use Tr33ControlWeb, :controller
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event}

  def index(conn, _params) do
    commands =
      Commands.command_types()
      |> Enum.map(&%Command{type: &1})

    events =
      Commands.event_types()
      |> Enum.map(&%Event{type: &1})

    enums = [Event.DisplayMode, Command.StripIndex, Event.ColorPalette, Event.ColorTemperature]

    conn
    |> render("index.html", commands: commands, events: events, enums: enums)
  end
end

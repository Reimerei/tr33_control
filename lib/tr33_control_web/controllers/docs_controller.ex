defmodule Tr33ControlWeb.DocsController do
  use Tr33ControlWeb, :controller
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Inputs}

  def index(conn, _params) do
    commands =
      Commands.command_types()
      |> Enum.map(fn {type, _} -> %Command{type: type} end)

    events =
      Commands.event_types()
      |> Enum.map(fn {type, _} -> %Event{type: type} end)

    enums = [Inputs.StripIndex, Inputs.DisplayMode, Inputs.ColorPalette, Inputs.ColorTemperature]

    conn
    |> render("index.html", commands: commands, events: events, enums: enums)
  end
end

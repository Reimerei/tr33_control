defmodule Tr33ControlWeb.CommandsChannel do
  use Phoenix.Channel
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Cache}

  def join("commands", msg, socket) do
    Logger.debug("Join in commands channel, msg: #{inspect(msg)}")
    forms = Cache.get_all() |> Enum.map(&render_form/1)

    {:ok, %{msgs: forms}, socket}
  end

  def handle_in("form_change", msg, socket) do
    msg
    |> normalize_data()
    |> Commands.create_command!()
    |> broadcast_form(socket)
    |> Commands.Cache.insert()
    |> Commands.send_command()

    {:noreply, socket}
  end

  def handle_in("button", msg, socket) do
    msg
    |> Commands.create_event!()
    |> Commands.send_event()

    {:noreply, socket}
  end

  defp broadcast_form(%Command{index: index, type: type} = command, socket) do
    %Command{type: prev_type} = Commands.Cache.get(index)

    if type != prev_type do
      command = Command.defaults(command)
      broadcast!(socket, "form", render_form(command))
      command
    else
      broadcast_from!(socket, "form", render_form(command))
      command
    end
  end

  defp render_form(command) do
    html =
      Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "form.html", command: command)

    %{id: "#{command.index}", html: html}
  end

  defp normalize_data(msg) do
    msg
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(%{"data" => []}, fn {key, value}, acc ->
      case key do
        "data_" <> _ ->
          Map.update!(acc, "data", fn data -> [value | data] end)

        _ ->
          Map.put(acc, key, value)
      end
    end)
  end
end

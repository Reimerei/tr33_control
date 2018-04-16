defmodule Tr33ControlWeb.CommandsChannel do
  use Phoenix.Channel
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  def join("commands", msg, socket) do
    Logger.debug("join in commands channel, msg: #{inspect(msg)}")
    {:ok, socket}
  end

  def handle_in("init", msg, socket) do
    Application.fetch_env!(:tr33_control, :commands)
    |> Enum.each(&push_form(&1, socket))

    {:noreply, socket}
  end

  def handle_in("form_change", msg, socket) do
    msg
    |> normalize_data()
    |> Commands.create_command!()
    |> broadcast_form(socket)
    |> Commands.send_command()

    {:noreply, socket}
  end

  defp broadcast_form({new_command, old_command}, socket) do
    if old_command.type != new_command.type do
      new_command = Command.defaults(new_command)
      broadcast!(socket, "form", render_form(new_command))
      new_command
    else
      broadcast_from!(socket, "form", render_form(new_command))
      new_command
    end
  end

  defp push_form(command = %Command{}, socket) do
    push(socket, "form", render_form(command))
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

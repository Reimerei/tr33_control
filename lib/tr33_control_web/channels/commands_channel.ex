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
    |> update_cache
    |> broadcast_form(socket)
    |> Commands.send_command()

    {:noreply, socket}
  end

  defp broadcast_form({old_command, new_command}, socket) do
    if old_command.type != new_command.type do
      broadcast!(socket, "form", render_form(new_command))
    else
      broadcast_from!(socket, "form", render_form(new_command))
    end

    new_command
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

  defp update_cache(new_command = %Command{}) do
    cache = Application.fetch_env!(:tr33_control, :commands)
    old_command = Enum.at(cache, new_command.index)

    Application.put_env(
      :tr33_control,
      :commands,
      List.replace_at(cache, new_command.index, new_command)
    )

    {old_command, new_command}
  end
end

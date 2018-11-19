defmodule Tr33ControlWeb.CommandsChannel do
  use Phoenix.Channel
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Preset, Event}

  @channel_event_name "form"

  def join("live_forms", msg, socket) do
    Logger.debug("Join in commands channel, msg: #{inspect(msg)}")

    {:ok, %{msgs: render_all(socket)}, socket}
  end

  def handle_in("form_change", %{"form_type" => "command"} = msg, socket) do
    new_command =
      msg
      |> normalize_data()
      |> Commands.new_command!()

    previous_command = Commands.get_command(new_command.index)
    send_and_update_form(new_command, previous_command, socket)

    {:noreply, socket}
  end

  def handle_in("form_change", %{"form_type" => "presets"} = msg, socket) do
    %Preset{name: name} =
      Map.get(msg, "load_preset")
      |> Commands.load_preset()

    socket = assign(socket, :preset_message, "Loaded preset #{name}")

    render_all(socket)
    |> Enum.each(&broadcast!(socket, @channel_event_name, &1))

    {:noreply, socket}
  end

  def handle_in("form_change", %{"form_type" => "settings"} = msg, socket) do
    settings_event =
      msg
      |> normalize_data()
      |> Commands.new_event!()
      |> Commands.send_event()

    msg = render_settings_form()
    broadcast_from!(socket, @channel_event_name, msg)
    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "command"} = msg, socket) do
    msg
    |> Commands.new_event!()
    |> Commands.send_event()

    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "presets"} = msg, socket) do
    message =
      case Commands.create_preset(msg) do
        {:ok, %Preset{name: name}} ->
          "Saved #{inspect(name)}"

        {:error, error} ->
          Logger.debug(inspect(error))
          "Error saving #{inspect(Map.get(msg, "name"))}"
      end

    socket = assign(socket, :preset_message, message)
    msg = render_presets_form(socket)

    broadcast!(socket, @channel_event_name, msg)

    {:noreply, socket}
  end

  defp send_and_update_form(%Command{type: type} = command, %Command{type: type}, socket) do
    msg =
      command
      |> Commands.send_command()
      |> render_command_form()

    broadcast_from!(socket, @channel_event_name, msg)
    command
  end

  defp send_and_update_form(%Command{} = command, _, socket) do
    msg =
      command
      |> Command.defaults()
      |> Commands.send_command()
      |> render_command_form

    broadcast!(socket, @channel_event_name, msg)
    command
  end

  defp render_all(socket) do
    render_all_command_forms() ++ [render_presets_form(socket), render_settings_form()]
  end

  defp render_all_command_forms() do
    0..Application.fetch_env!(:tr33_control, :command_max_index)
    |> Enum.map(&render_command_form/1)
  end

  defp render_command_form(%Command{index: index}), do: render_command_form(index)

  defp render_command_form(index) when is_integer(index) do
    assigns = %{
      command: Commands.get_command(index)
    }

    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_command.html", assigns)

    %{id: "#{index}", html: html}
  end

  defp render_presets_form(%Phoenix.Socket{assigns: socket_assigns}) do
    assigns = %{
      presets: Commands.list_presets(),
      current_preset: Commands.current_preset(),
      message: Map.get(socket_assigns, :preset_message, "")
    }

    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_presets.html", assigns)

    %{id: "presets", html: html}
  end

  defp render_settings_form() do
    assigns = %{
      event: Commands.get_event(:update_settings)
    }

    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_settings.html", assigns)

    %{id: "settings", html: html}
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

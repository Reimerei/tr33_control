defmodule Tr33ControlWeb.CommandsChannel do
  use Phoenix.Channel
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Preset, Event}

  def join("live_forms", msg, socket) do
    Logger.debug("Join in commands channel, msg: #{inspect(msg)}")
    command_forms = Commands.list_commands() |> Enum.map(&render_command_form/1)
    presets_form = Commands.list_presets() |> render_presets_form()
    color_palette_form = Commands.get_color_palette() |> render_color_palette_form()

    {:ok, %{msgs: [presets_form, color_palette_form] ++ command_forms}, socket}
  end

  def handle_in("form_change", %{"form_type" => "command"} = msg, socket) do
    msg
    |> normalize_data()
    |> Commands.new_command!()
    |> broadcast_form(socket)
    |> Commands.send_command()

    {:noreply, socket}
  end

  def handle_in("form_change", %{"form_type" => "presets"} = msg, socket) do
    %Preset{commands: commands, name: name} =
      Map.get(msg, "load_preset")
      |> Commands.load_preset()

    Enum.each(commands, fn command -> broadcast!(socket, "form", render_command_form(command)) end)
    assigns = %{message: "Loaded preset #{name}", current_name: name}

    presets_form = Commands.list_presets() |> render_presets_form(assigns)
    broadcast(socket, "form", presets_form)

    color_palette_form = Commands.get_color_palette() |> render_color_palette_form()
    broadcast(socket, "form", color_palette_form)

    {:noreply, socket}
  end

  def handle_in("form_change", %{"form_type" => "color_palette"} = msg, socket) do
    msg
    |> normalize_data()
    |> Commands.new_event!()
    |> broadcast_form(socket)
    |> persist_event()
    |> Commands.send_event()

    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "command"} = msg, socket) do
    msg
    |> Commands.new_event!()
    |> Commands.send_event()

    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "presets"} = msg, socket) do
    result =
      case Commands.create_preset(msg) do
        {:ok, %Preset{name: name}} -> "Saved #{inspect(name)}"
        {:error, _} -> "Error saving #{inspect(Map.get(msg, "name"))}"
      end

    presets_form =
      Commands.list_presets()
      |> render_presets_form(%{message: result, current_name: Map.get(msg, "name")})

    broadcast(socket, "form", presets_form)

    {:noreply, socket}
  end

  defp broadcast_form(%Command{index: index, type: type} = command, socket) do
    %Command{type: prev_type} = Commands.get_command(index)

    if type != prev_type do
      command = Command.defaults(command)
      broadcast!(socket, "form", render_command_form(command))
      command
    else
      broadcast_from!(socket, "form", render_command_form(command))
      command
    end
  end

  defp broadcast_form(%Event{type: :set_color_palette, data: [selected]} = event, socket) do
    broadcast!(socket, "form", render_color_palette_form(selected))
    event
  end

  defp render_command_form(%Command{} = command, assigns \\ %{}) do
    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_command.html", command: command)

    %{id: "#{command.index}", html: html}
  end

  defp render_presets_form(presets, assigns \\ %{}) when is_list(presets) do
    html =
      Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_presets.html", Map.put(assigns, :presets, presets))

    %{id: "presets", html: html}
  end

  defp render_color_palette_form(selected) when is_integer(selected) do
    assigns = %{
      palettes: Commands.list_color_palettes(),
      selected: selected
    }

    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_color_palette.html", assigns)

    %{id: "color_palette", html: html}
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

  defp persist_event(%Event{type: :set_color_palette, data: [selected]} = event) do
    Commands.set_color_palette(selected)
    event
  end
end

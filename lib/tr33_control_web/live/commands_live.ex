defmodule Tr33ControlWeb.CommandsLive do
  use Phoenix.LiveView

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Preset, Command}

  def render(assigns) do
    Tr33ControlWeb.CommandsView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket), do: Commands.subscribe()

    socket =
      socket
      |> assign(:preset_flash, nil)
      |> fetch_state()

    {:ok, socket}
  end

  def handle_event("load_preset", %{"preset_name" => name}, socket) do
    Commands.load_preset(name)

    Commands.update_subscribers()

    socket
    |> assign(:preset_current, name)
    |> assign(:preset_flash, "Preset #{inspect(name)} loaded")
    |> reply
  end

  def handle_event("save_preset", %{"preset" => params}, socket) do
    case Commands.create_preset(params) do
      {:ok, %Preset{name: name}} ->
        socket
        |> assign(:preset_flash, "Preset #{inspect(name)} written")
        |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
        |> reply

      {:error, changeset} ->
        socket
        |> assign(:preset_flash, "Error writing preset")
        |> assign(:preset_changeset, changeset)
        |> reply
    end
  end

  def handle_event("form_change", %{"action" => "event"} = params, socket) do
    params
    |> parse_data()
    |> Commands.new_event!()
    |> Commands.send()

    Commands.update_subscribers()

    reply(socket)
  end

  def handle_event("form_change", %{"action" => "command"} = params, socket) do
    new_command =
      params
      |> parse_data()
      |> Commands.new_command!()

    %Command{type: new_type, index: index} = new_command
    %Command{type: old_type} = Commands.get_command(index)

    if new_type != old_type do
      new_command
      |> Command.defaults()
    else
      new_command
    end
    |> Commands.send()

    Commands.update_subscribers()

    reply(socket)
  end

  def handle_event("add_command", _, socket) do
    Commands.add_command()
    Commands.update_subscribers()

    reply(socket)
  end

  def handle_event("delete_command", _, socket) do
    Commands.delete_last_command()
    Commands.update_subscribers()

    reply(socket)
  end

  def handle_event("event_button", type, socket) do
    %{type: type}
    |> Commands.new_event!()
    |> Commands.send()

    reply(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  def handle_info(:update, socket) do
    socket
    |> fetch_state
    |> reply
  end

  def handle_info(info, socket) do
    Logger.warn("Unhandled info #{inspect(info)}}")
    reply(socket)
  end

  defp fetch_state(socket) do
    socket
    |> assign(:presets, Commands.list_presets())
    |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
    |> assign(:settings_event, Commands.get_event(:update_settings))
    |> assign(:commands, Commands.list_commands())
  end

  defp reply(socket), do: {:noreply, socket}

  defp parse_data(%{"data" => form_data} = params) do
    data =
      form_data
      |> Enum.sort_by(fn {index, _} -> index end)
      |> Enum.map(fn {_, value} -> Integer.parse(value) |> elem(0) end)

    %{params | "data" => data}
  end

  defp parse_data(params), do: Map.put(params, "data", [])
end

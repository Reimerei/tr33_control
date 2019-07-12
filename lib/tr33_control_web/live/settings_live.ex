defmodule Tr33ControlWeb.SettingsLive do
  use Phoenix.LiveView

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Preset}

  def render(assigns) do
    Tr33ControlWeb.CommandsView.render("_settings.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket), do: Commands.subscribe()

    socket =
      socket
      |> assign(:preset_flash, nil)
      |> fetch()

    {:ok, socket}
  end

  def handle_event("load_preset", %{"name" => name}, socket) do
    Logger.debug("load_preset: #{inspect(name)}")
    Commands.load_preset(name)

    socket
    |> assign(:preset_current, name)
    |> assign(:preset_flash, "Preset #{inspect(name)} loaded")
    |> reply()
  end

  def handle_event("save_preset", %{"preset" => params}, socket) do
    Logger.debug("save_preset: #{inspect(params)}")

    case Commands.create_preset(params) do
      {:ok, %Preset{name: name}} ->
        socket
        |> assign(:preset_flash, "Preset #{inspect(name)} written")
        |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
        |> reply()

      {:error, changeset} ->
        Logger.error("Error creating preset' #{inspect(changeset)}")

        socket
        |> assign(:preset_flash, "Error writing preset")
        |> assign(:preset_changeset, changeset)
        |> reply()
    end
  end

  def handle_event("settings_change", params, socket) do
    Logger.debug("settings_change: #{inspect(params)}")

    params
    |> Map.put("type", "update_settings")
    |> Commands.new_event!()
    |> Commands.send()

    reply(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("SettingsLive: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  def handle_info({:event_update, :update_settings}, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info({:preset_update, _}, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info(data, socket) do
    # Logger.debug("SettingsLive: Unhandled info #{inspect(data)}")
    reply(socket)
  end

  defp fetch(socket) do
    settings_inputs =
      Commands.get_event(:update_settings)
      |> Commands.inputs()

    socket
    |> assign(:presets, Commands.list_presets())
    |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
    |> assign(:settings_inputs, settings_inputs)
  end

  defp reply(socket), do: {:noreply, socket}
end

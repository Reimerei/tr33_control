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
      |> current_preset_changeset()
      |> fetch()

    {:ok, socket}
  end

  def handle_event("preset_load", %{"name" => name}, socket) do
    Logger.debug("preset_load: #{inspect(name)}")
    %Preset{name: name} = Commands.load_preset(name)

    socket
    |> current_preset_changeset()
    |> fetch("Preset #{inspect(name)} loaded")
    |> reply()
  end

  def handle_event("preset_save", %{"preset" => params}, socket) do
    case Commands.create_preset(params) do
      {:ok, %Preset{name: name}} ->
        socket
        |> assign(:preset_flash, "Preset #{inspect(name)} saved")
        |> current_preset_changeset()
        |> fetch()
        |> reply()

      {:error, changeset} ->
        Logger.error("Error creating preset' #{inspect(changeset)}")

        socket
        |> assign(:preset_flash, "Error writing preset")
        |> assign(:preset_changeset, changeset)
        |> fetch()
        |> reply()
    end
  end

  def handle_event("preset_validate", %{"preset" => params}, socket) do
    changeset =
      %Preset{}
      |> Commands.change_preset(params)
      |> Map.put(:action, :insert)

    socket
    |> assign(:preset_changeset, changeset)
    |> fetch()
    |> reply()
  end

  def handle_event("preset_delete", %{"name" => name}, socket) do
    flash =
      case Commands.delete_preset(name) do
        {:ok, true} -> "Preset #{inspect(name)} deleted"
        _ -> nil
      end

    socket
    |> current_preset_changeset()
    |> fetch(flash)
    |> reply()
  end

  def handle_event("preset_set_default", %{"name" => name}, socket) do
    flash =
      case Commands.set_default_preset(name) do
        %Preset{name: name} -> "Set preset #{inspect(name)} as default"
        nil -> nil
      end

    socket
    |> fetch(flash)
    |> reply
  end

  def handle_event("settings_change", params, socket) do
    Logger.debug("settings_change: #{inspect(params)}")

    params
    |> Map.put("type", "update_settings")
    |> Commands.new_event!()
    |> Commands.send()

    socket
    |> fetch()
    |> reply()
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

  def handle_info({:preset_update, _name}, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info({:preset_load, name}, socket) do
    socket
    |> current_preset_changeset()
    |> fetch("Preset #{name} loaded")
    |> reply
  end

  def handle_info(_data, socket) do
    # Logger.debug("SettingsLive: Unhandled info #{inspect(data)}")
    reply(socket)
  end

  defp current_preset_changeset(socket) do
    socket
    |> assign(:preset_changeset, Commands.get_current_preset() |> Commands.change_preset())
  end

  defp fetch(socket, preset_flash \\ nil) do
    settings_inputs =
      Commands.get_event(:update_settings)
      |> Commands.inputs()

    presets =
      Commands.list_presets()
      |> Enum.sort_by(fn %Preset{name: name} -> name end)

    socket
    |> maybe_write_flash(preset_flash)
    |> assign(:presets, presets)
    |> assign(:settings_inputs, settings_inputs)
  end

  defp reply(socket), do: {:noreply, socket}

  defp maybe_write_flash(socket, nil), do: socket
  defp maybe_write_flash(socket, flash), do: assign(socket, :preset_flash, flash)
end

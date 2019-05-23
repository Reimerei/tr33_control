defmodule Tr33ControlWeb.SettingsLive do
  use Phoenix.LiveView

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Preset}
  alias Tr33Control.Commands.Inputs.{Select}

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
    Commands.notify_subscribers(:command_update)

    socket
    |> assign(:preset_current, name)
    |> assign(:preset_flash, "Preset #{inspect(name)} loaded")
    |> reply_and_notify
  end

  def handle_event("save_preset", %{"preset" => params}, socket) do
    Logger.debug("save_preset: #{inspect(params)}")

    case Commands.create_preset(params) do
      {:ok, %Preset{name: name}} ->
        socket
        |> assign(:preset_flash, "Preset #{inspect(name)} written")
        |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
        |> reply_and_notify

      {:error, changeset} ->
        Logger.error("Error creating preset' #{inspect(changeset)}")

        socket
        |> assign(:preset_flash, "Error writing preset")
        |> assign(:preset_changeset, changeset)
        |> reply_and_notify
    end
  end

  def handle_event("settings_change", params, socket) do
    Logger.debug("settings_change: #{inspect(params)}")

    params
    |> Map.put("type", "update_settings")
    |> Commands.new_event!()
    |> Commands.send()

    reply_and_notify(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  def handle_info(:settings_update, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info(_, socket), do: reply(socket)

  defp fetch(socket) do
    settings_event = Commands.get_event(:update_settings)
    inputs = Commands.inputs(settings_event)

    settings_selects = for %Select{} = input <- inputs, do: input

    socket
    |> assign(:presets, Commands.list_presets())
    |> assign(:preset_changeset, Commands.change_preset(%Preset{}))
    |> assign(:settings_selects, settings_selects)
  end

  defp reply_and_notify(socket) do
    Commands.notify_subscribers(:settings_update)
    reply(socket)
  end

  defp reply(socket), do: {:noreply, socket}
end

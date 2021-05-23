defmodule Tr33ControlWeb.ControlLive do
  use Tr33ControlWeb, :live_view
  require Logger

  alias Phoenix.LiveView.Socket
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command
  alias Tr33ControlWeb.{CommandComponent, SettingsComponent, CommandHeaderComponent}

  def mount(_params, _session, socket) do
    if connected?(socket), do: Commands.subscribe()

    socket =
      socket
      |> assign(active_command: 0)
      |> fetch()

    {:ok, socket}
  end

  def handle_event("set_active_command", %{"index" => index}, socket) do
    socket =
      socket
      |> assign(active_command: String.to_integer(index))

    {:noreply, socket}
  end

  def handle_event(event, data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    {:noreply, socket}
  end

  def handle_info({:command_update, command = %Command{}}, %Socket{} = socket) do
    send_update(CommandHeaderComponent, id: command.index, command: command)
    send_update(CommandComponent, id: :active_command, command: command)

    {:noreply, fetch(socket)}
  end

  def handle_info({:event_update, :update_settings}, socket) do
    send_update(SettingsComponent, id: :settings)
    {:noreply, socket}
  end

  def handle_info({:preset_update, _name}, socket) do
    send_update(SettingsComponent, id: :settings)
    {:noreply, socket}
  end

  def handle_info({:preset_load, _name}, socket) do
    send_update(SettingsComponent, id: :settings)
    {:noreply, socket}
  end

  def handle_info({:modifier_update, {id, _}}, socket) do
    send_update(CommandComponent, id: id)
    {:noreply, socket}
  end

  def handle_info(data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled info #{inspect(data)}")
    {:noreply, socket}
  end

  defp fetch(socket) do
    socket
    |> assign(command_count: Commands.count_commands())
  end
end

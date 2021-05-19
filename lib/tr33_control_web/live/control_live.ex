defmodule Tr33ControlWeb.ControlLive do
  use Tr33ControlWeb, :live_view
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command
  alias Tr33ControlWeb.{CommandComponent, SettingsComponent}

  def mount(_params, _session, socket) do
    if connected?(socket), do: Commands.subscribe()

    {:ok, fetch(socket)}
  end

  def handle_event(event, data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    {:noreply, socket}
  end

  def handle_info({:command_update, command = %Command{}}, socket) do
    send_update(CommandComponent, id: command.index)
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

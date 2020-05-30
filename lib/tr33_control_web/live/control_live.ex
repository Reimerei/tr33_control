defmodule Tr33ControlWeb.ControlLive do
  use Tr33ControlWeb, :live_view
  require Logger

  alias Tr33Control.Commands
  alias Tr33ControlWeb.CommandComponent

  def mount(_params, _session, socket) do
    if connected?(socket), do: Commands.subscribe()

    {:ok, socket}
  end

  def handle_event(event, data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    {:noreply, socket}
  end

  def handle_info({:command_update, id}, socket) do
    send_update(CommandComponent, id: id)
    {:noreply, socket}
  end

  def handle_info(data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled info #{inspect(data)}")
    {:noreply, socket}
  end
end

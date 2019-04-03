defmodule Tr33ControlWeb.IndexLive do
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    Tr33ControlWeb.CommandsView.render("index.html", assigns)
  end

  def mount(_, socket) do
    {:ok, socket}
  end

  def handle_event(event, data, socket) do
    Logger.warn("Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  defp reply(socket), do: {:noreply, socket}
end

defmodule Tr33ControlWeb.TwangLive do
  alias Tr33Control.Commands
  use Phoenix.LiveView
  require Logger

  @speed 70
  def render(assigns) do
    ~L"""
    <div id="test" phx-keyup="key_up" phx-keydown="key_down" phx-target="window">
      <p>Move: A/D</p>
      Fire: W
    </div>
    """
  end

  def mount(_, socket) do
    {:ok, socket}
  end

  def handle_event("key_down", "ArrowLeft", socket) do
    Commands.new_event!(%{type: :joystick, data: [@speed, 0]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event("key_up", "ArrowLeft", socket) do
    Commands.new_event!(%{type: :joystick, data: [0, 0]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event("key_down", "ArrowRight", socket) do
    Commands.new_event!(%{type: :joystick, data: [@speed * -1, 0]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event("key_up", "ArrowRight", socket) do
    Commands.new_event!(%{type: :joystick, data: [0, 0]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event("key_down", "ArrowUp", socket) do
    Commands.new_event!(%{type: :joystick, data: [0, 255]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event("key_up", "ArrowUp", socket) do
    Commands.new_event!(%{type: :joystick, data: [0, 0]})
    |> Commands.send_to_esp()

    reply(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("IndexLive: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  defp reply(socket), do: {:noreply, socket}
end

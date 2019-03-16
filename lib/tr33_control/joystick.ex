defmodule Tr33Control.Joystick do
  use GenServer
  require Logger
  alias Tr33Control.Commands.Event

  @input_dev "/dev/input/event0"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def init(_) do
    {:ok, _} = InputEvent.start_link(@input_dev)

    {:ok, %{}}
  end

  def handle_info({:input_event, @input_dev, [_, {:ev_key, :btn_trigger, 1}]}, state) do
    event = Tr33Control.Commands.get_event(:update_settings)

    Tr33Control.Commands.send_event(%Event{event | data: [Enum.random(0..10), 0]})

    {:noreply, state}
  end

  def handle_info({:input_event, @input_dev, msg}, state) do
    Logger.debug(inspect(msg))
    {:noreply, state}
  end
end

defmodule Tr33Control.Joystick do
  use GenServer
  require Logger
  alias Tr33Control.Commands.Event

  @input_dev "/dev/input/event0"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def init(_) do
    result = InputEvent.start_link(@input_dev)
    Logger.info("Tried to listen on #{@input_dev} for joystick commands, result: #{inspect(result)}")
    {:ok, %{}}
  end

  def handle_info({:input_event, @input_dev, [_, {:ev_key, :btn_trigger, 1}]}, state) do
    Tr33Control.Commands.get_event(:update_settings)
    |> Map.update(:data, [], &iterate(&1, 0, Event.ColorPalette))
    |> Tr33Control.Commands.send()

    Tr33Control.Commands.notify_subscribers(:command_update)
    Tr33Control.Commands.notify_subscribers(:settings_update)

    {:noreply, state}
  end

  def handle_info({:input_event, @input_dev, msg}, state) do
    Logger.debug(inspect(msg))
    {:noreply, state}
  end

  defp iterate(data, index, enum) do
    List.update_at(data, index, fn value ->
      next = value + 1

      case enum.__enum_map__() |> Keyword.values() |> Enum.member?(next) do
        true -> next
        false -> 0
      end
    end)
  end
end

defmodule Tr33Control.Joystick do
  use GenServer
  require Logger
  alias Tr33Control.Commands.{Event, Command}
  alias Tr33Control.Commands

  @input_dev "/dev/input/event0"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def init(_) do
    result = InputEvent.start_link(@input_dev)
    Logger.info("Tried to listen on #{@input_dev} for joystick commands, result: #{inspect(result)}")
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_info({:input_event, @input_dev, joystick_events}, state) when is_list(joystick_events) do
    Enum.each(joystick_events, &handle_joystick_event/1)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp handle_joystick_event({:ev_key, :btn_trigger, 1}) do
    Commands.get_event(:update_settings)
    |> Map.update(:data, [], &iterate(&1, 0, Event.ColorPalette))
    |> Commands.send()
  end

  defp handle_joystick_event({:ev_abs, name, value})
       when name in [:abs_rudder, :abs_throttle, :abs_hat0x, :abs_hat0y] do
    if Commands.get_current_preset_name() == "joystick" do
      case Commands.list_commands() |> Enum.find(fn %Command{type: type} -> type == :mapped_shape end) do
        nil ->
          :noop

        command ->
          Map.update(command, :data, [], &update_mapped_shape_data(&1, name, value))
          |> Commands.send()
      end
    end
  end

  defp handle_joystick_event({:ev_key, :btn_base5, 1}) do
    Commands.load_preset("joystick")
  end

  defp handle_joystick_event(_event), do: :noop

  defp iterate(data, index, enum) do
    List.update_at(data, index, fn value ->
      next = value + 1

      case enum.__enum_map__() |> Keyword.values() |> Enum.member?(next) do
        true -> next
        false -> 0
      end
    end)
  end

  defp interate_num(data, index, incr) when incr > 0 do
    List.update_at(data, index, fn
      v when v > 255 - incr -> 0
      v -> v + incr
    end)
  end

  defp interate_num(data, index, incr) when incr < 0 do
    List.update_at(data, index, fn
      v when v < 0 - incr -> 255
      v -> v + incr
    end)
  end

  defp interate_num(data, _, _), do: data

  defp update_mapped_shape_data(data, :abs_hat0x, joystick_value) do
    interate_num(data, 1, joystick_value * 15)
  end

  defp update_mapped_shape_data(data, :abs_rudder, joystick_value) do
    List.update_at(data, 2, &smooth_jitter(&1, joystick_value))
  end

  defp update_mapped_shape_data(data, :abs_throttle, joystick_value) do
    List.update_at(data, 3, &smooth_jitter(&1, joystick_value))
  end

  defp update_mapped_shape_data(data, :abs_hat0y, joystick_value) do
    interate_num(data, 4, joystick_value * -10)
  end

  defp smooth_jitter(current, new) when abs(new - current) > 1, do: new
  defp smooth_jitter(current, _), do: current
end

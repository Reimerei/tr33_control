defmodule Tr33Control.Joystick do
  use GenServer
  require Logger
  alias Tr33Control.Commands.{Event, Command, Inputs}
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
    if Commands.get_current_preset_name() == "joystick" do
      Commands.get_event(:update_settings)
      |> Map.update(:data, [], &iterate(&1, 0, Inputs.ColorPalette))
      |> Commands.send()
    end

    if Commands.get_current_preset_name() == "twang" do
      Commands.new_event!(%{type: :joystick, data: [0, 160]})
      |> Commands.send()
    end
  end

  defp handle_joystick_event({:ev_key, :btn_trigger, 0}) do
    if Commands.get_current_preset_name() == "twang" do
      Commands.new_event!(%{type: :joystick, data: [0, 0]})
      |> Commands.send()
    end
  end

  defp handle_joystick_event({:ev_abs, name, value})
       when name in [:abs_x, :abs_y, :abs_hat0x, :abs_hat0y] do
    if Commands.get_current_preset_name() == "joystick" do
      case Commands.list_commands() |> Enum.find(fn %Command{type: type} -> type == :mapped_shape end) do
        nil ->
          :noop

        command ->
          Map.update(command, :data, [], &update_mapped_shape_data(&1, name, value))
          |> Commands.send()
      end
    end

    if Commands.get_current_preset_name() == "twang" do
      twang_event(name, value)
      |> Commands.send()
    end
  end

  defp handle_joystick_event({:ev_key, :btn_base5, 1}) do
    if Commands.get_current_preset_name() == "twang" do
      Commands.load_preset("joystick")
    else
      Commands.load_preset("twang")
    end
  end

  defp handle_joystick_event(event), do: Logger.debug(inspect(event))
  # defp handle_joystick_event(_event), do: :ok

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

  defp update_mapped_shape_data(data, :abs_x, joystick_value) do
    List.update_at(data, 2, &smooth_jitter(&1, joystick_value))
  end

  defp update_mapped_shape_data(data, :abs_y, joystick_value) do
    List.update_at(data, 3, &smooth_jitter(&1, joystick_value))
  end

  defp update_mapped_shape_data(data, :abs_hat0y, joystick_value) do
    interate_num(data, 4, joystick_value * -10)
  end

  defp twang_event(:abs_y, value) do
    Commands.new_event!(%{type: :joystick, data: [round((value - 127) / 2) * -1, 0]})
  end

  # defp twang_event(:abs_hat0y, value) do
  #   Commands.new_event!(%{type: :joystick, data: [max(value * -1, -126)]})
  # end 

  defp twang_event(_, _), do: %Event{type: :beat}

  defp smooth_jitter(current, new) when abs(new - current) > 1, do: new
  defp smooth_jitter(current, _), do: current
end

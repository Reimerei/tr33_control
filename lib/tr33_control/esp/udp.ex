defmodule Tr33Control.ESP.UDP do
  use GenServer
  require Logger

  @tick_interval_ms 25
  @max_queue_len 1000 / 25

  def start_link({host, port, process_name}) when is_binary(host) and is_number(port) do
    GenServer.start_link(__MODULE__, {host, port}, name: process_name)
  end

  def send(binary, process_name) when is_binary(binary) do
    GenServer.cast(process_name, {:send, binary})
  end

  def toggle_debug() do
    current = Application.get_env(:tr33_control, :udp_debug, false)
    Application.put_env(:tr33_control, :udp_debug, not current)
  end

  def init({host, port}) do
    Logger.info("UDP: Connecting to #{host} on port #{port}")

    local_port = Enum.random(5000..65535)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])

    state = %{
      socket: socket,
      last_packet: System.os_time(:millisecond),
      queue: :queue.new(),
      host: host |> to_charlist(),
      port: port,
      sequence: 0
    }

    Logger.info("UDP: Connected!")

    :timer.send_interval(@tick_interval_ms, :tick)

    {:ok, state}
  end

  def handle_cast({:send, binary}, %{queue: queue} = state) do
    state =
      if :queue.len(queue) < @max_queue_len do
        %{state | queue: :queue.in(binary, queue)}
      else
        state
      end

    {:noreply, state}
  end

  def handle_info(:tick, %{queue: queue} = state) do
    state =
      case :queue.out(queue) do
        {:empty, _} ->
          state

        {{:value, binary}, rest} ->
          # todo: send multiple commands in one packet
          state = transmit_binary(binary, state)
          %{state | queue: rest}
      end

    {:noreply, state}
  end

  defp transmit_binary(binary, state = %{socket: socket, port: port, host: host}) when is_binary(binary) do
    result = :gen_udp.send(socket, host, port, binary)

    if Application.get_env(:tr33_control, :udp_debug, false) do
      Logger.debug(
        "UDP: Send packet to #{inspect(host)}:#{inspect(port)} result: #{inspect(result)} content: #{inspect(binary)}"
      )
    end

    state
  end
end

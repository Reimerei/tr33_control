defmodule Tr33Control.Commands.UDP do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Event, Command}

  @udp_interval_ms 25
  @max_queue_len 1000 / 25

  def start_link({host, port}) when is_binary(host) and is_number(port) do
    GenServer.start_link(__MODULE__, {host, port}, [{:name, __MODULE__}])
  end

  def send(struct) do
    binary = to_binary(struct)
    GenServer.cast(__MODULE__, {:send, binary})
    struct
  end

  def resync() do
    (Commands.list_commands() ++ Commands.list_events())
    |> Enum.map(&send/1)
  end

  def debug() do
    Application.put_env(:tr33_control, :udp_debug, true)
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
      port: port
    }

    Logger.info("UDP: Connected!")

    resync()
    state = handle_tick(state)

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

  def handle_info(:tick, state) do
    state = handle_tick(state)
    {:noreply, state}
  end

  defp to_binary(%Command{} = command), do: Command.to_binary(command)
  defp to_binary(%Event{} = event), do: Event.to_binary(event)

  defp handle_tick(%{queue: queue} = state) do
    Process.send_after(self(), :tick, @udp_interval_ms)

    case :queue.out(queue) do
      {:empty, _} ->
        state

      {{:value, binary}, rest} ->
        transmit_binary(binary, state)
        %{state | queue: rest}
    end
  end

  defp transmit_binary(binary, %{socket: socket, port: port, host: host}) when is_binary(binary) do
    result = :gen_udp.send(socket, host, port, binary)

    if Application.get_env(:tr33_control, :udp_debug, false) do
      Logger.debug(
        "UDP: Send packet to #{inspect(host)}:#{inspect(port)} result: #{inspect(result)} content: #{inspect(binary)}"
      )
    end
  end
end

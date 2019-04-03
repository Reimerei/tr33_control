defmodule Tr33Control.Commands.Socket do
  use GenServer
  require Logger
  alias Tr33Control.Commands.{Event, Command, Cache}

  @host Application.fetch_env!(:tr33_control, :esp32_ip) |> to_charlist() |> :inet.parse_address() |> elem(1)
  @port Application.fetch_env!(:tr33_control, :esp32_port) |> String.to_integer()
  @silent_period_ms 0
  @idle_timeout_ms 250

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send(struct) do
    packet = to_packet(struct)
    GenServer.cast(__MODULE__, {:send, packet})
  end

  def resync() do
    GenServer.cast(__MODULE__, :resync)
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    local_port = Enum.random(5000..65535)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])

    state = %{
      socket: socket,
      last_packet: System.os_time(:millisecond),
      queue: queue_all_cache()
    }

    {:ok, state, @idle_timeout_ms}
  end

  def handle_cast({:send, packet}, state) do
    %{socket: socket, last_packet: last_packet} = state

    if System.os_time(:millisecond) > last_packet + @silent_period_ms do
      send_packet(packet, socket)
      {:noreply, %{state | last_packet: System.os_time(:millisecond)}, @idle_timeout_ms}
    else
      {:noreply, state, @idle_timeout_ms}
    end
  end

  def handle_cast(:resync, state) do
    {:noreply, %{state | refresh_queue: queue_all_cache()}, @idle_timeout_ms}
  end

  def handle_info(:timeout, %{refresh_queue: []} = state) do
    {:noreply, %{state | refresh_queue: queue_all_cache()}, @idle_timeout_ms}
  end

  def handle_info(:timeout, %{refresh_queue: [head | rest]} = state) do
    head
    |> send()

    {:noreply, %{state | refresh_queue: rest}, @idle_timeout_ms}
  end

  defp send_packet(packet, socket) when is_binary(packet) do
    result = :gen_udp.send(socket, @host, @port, packet)

    Logger.debug(
      "Sending packet to #{inspect(@host)}:#{inspect(@port)} result: #{inspect(result)} content: #{inspect(packet)}"
    )
  end

  defp queue_all_cache() do
    Cache.all_commands() ++ Cache.all_events()
  end

  def to_packet(%Command{} = command), do: Command.to_binary(command)
  def to_packet(%Event{} = event), do: Event.to_binary(event)
end

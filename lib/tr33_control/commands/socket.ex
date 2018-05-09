defmodule Tr33Control.Commands.Socket do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Cache}

  @host {192, 168, 0, 42}
  @port 1337
  @silent_period_ms 0
  @idle_timeout_ms 250
  @enable_log false

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send(command = %Command{}) do
    GenServer.cast(__MODULE__, {:send, command})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    local_port = Enum.random(5000..65535)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])

    state = %{
      socket: socket,
      last_packet: System.os_time(:milliseconds),
      refresh_queue: initial_queue()
    }

    {:ok, state, @idle_timeout_ms}
  end

  def handle_cast({:send, %Command{index: index} = command}, state) do
    %{socket: socket, last_packet: last_packet, refresh_queue: queue} = state

    if System.os_time(:milliseconds) > last_packet + @silent_period_ms do
      send_command(command, socket)
      {:noreply, %{state | last_packet: System.os_time(:milliseconds)}, @idle_timeout_ms}
    else
      {:noreply, state, @idle_timeout_ms}
    end
  end

  def handle_info(:timeout, %{refresh_queue: []} = state) do
    {:noreply, %{state | refresh_queue: initial_queue()}, @idle_timeout_ms}
  end

  def handle_info(:timeout, %{refresh_queue: [index | rest]} = state) do
    index
    |> Cache.get()
    |> send

    {:noreply, %{state | refresh_queue: rest}, @idle_timeout_ms}
  end

  defp send_command(%Command{} = command, socket) do
    packet = Command.to_binary(command)
    result = :gen_udp.send(socket, @host, @port, packet)

    if @enable_log do
      Logger.debug("Sending packet to #{inspect(@host)}: #{inspect(result)} content: #{inspect(packet)}")
    end
  end

  defp initial_queue() do
    Cache.get_all()
    |> Enum.map(& &1.index)
  end
end

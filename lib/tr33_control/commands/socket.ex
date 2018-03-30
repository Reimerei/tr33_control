defmodule Tr33Control.Commands.Socket do
  use GenServer
  require Logger
  alias Tr33Control.Commands.Command

  @host {192, 168, 0, 42}
  @port 1337
  @idle_period_ms 50

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send_command(%Command{} = command) do
    GenServer.call(__MODULE__, {:send_command, command})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    local_port = Enum.random(5000..65535)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])
    {:ok, %{socket: socket, last_command: System.os_time(:milliseconds)}}
  end

  def handle_call({:send_command, command}, _from, state) do
    %{socket: socket, last_command: last_command} = state

    case System.os_time(:milliseconds) > last_command + @idle_period_ms do
      true ->
        result = do_send_command(command, socket)
        {:reply, result, %{state | last_command: System.os_time(:milliseconds)}}

      false ->
        {:reply, :ok, state}
    end
  end

  defp do_send_command(command, socket) do
    packet =
      command
      |> Command.to_binary()

    :ok = result = :gen_udp.send(socket, @host, @port, packet)
    Logger.info("Send packet to #{inspect(@host)}:#{@port} data: #{inspect(packet)}")
  end
end

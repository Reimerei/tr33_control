defmodule Tr33Control.Commands.Socket do
  use GenServer
  require Logger
  alias Tr33Control.Commands.Command

  @host {192, 168, 1, 142}
  @port 1337

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
    {:ok, %{socket: socket}}
  end

  def handle_call({:send_command, command}, _from, state = %{socket: socket}) do
    packet =
      command
      |> Command.to_binary()



    :ok = result = :gen_udp.send(socket, @host, @port, packet)

    Logger.info("Send packet to #{inspect @host}:#{@port}")

    {:reply, result, state}
  end
end

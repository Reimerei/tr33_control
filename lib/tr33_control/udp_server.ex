defmodule Tr33Control.UdpServer do
  use GenServer
  require Logger
  alias Tr33Control.{Commands, ESP}

  @listen_port Application.fetch_env!(:tr33_control, :udp_listen_port)
  @resync_packet "resync"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    {:ok, socket} = :gen_udp.open(@listen_port, [:binary])
    Logger.info("#{__MODULE__}: Listening on port #{@listen_port}")

    state = %{
      socket: socket
    }

    {:ok, state}
  end

  def handle_info({:udp, _socket, address, port, @resync_packet}, state) do
    Logger.debug("#{__MODULE__}: Resync request from #{inspect(address)}:#{inspect(port)}")
    ESP.resync(address, port)
    {:noreply, state}
  end

  def handle_info({:udp, _socket, address, port, data}, state) do
    Logger.debug("#{__MODULE__}: Incoming command: #{inspect(data)}, from: #{inspect(address)}:#{inspect(port)}")

    case Commands.new_command(data) do
      {:ok, command} ->
        Commands.send_to_esp(command)
        # send_ack(socket, address, port)
        Logger.debug("#{__MODULE__}: Valid command: #{inspect(command)}")

      {:error, _error} ->
        case Commands.new_event(data) do
          {:ok, event} ->
            Commands.send_to_esp(event)
            # send_ack(socket, address, port)
            Logger.debug("#{__MODULE__}: Valid event: #{inspect(event)}")

          {:error, error} ->
            Logger.debug("#{__MODULE__}: Inalid command or event: #{inspect(data)}, Error: #{inspect(error)}")
        end
    end

    {:noreply, state}
  end

  def handle_info(other, state) do
    Logger.warn(" Unexpected message: #{inspect(other)}")
    {:noreply, state}
  end

  def send_ack(socket, address, port) do
    :gen_udp.send(socket, address, port, <<42>>)
  end
end

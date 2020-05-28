defmodule Tr33Control.UdpServer do
  use GenServer
  require Logger
  alias Tr33Control.Commands

  @listen_port Application.fetch_env!(:tr33_control, :udp_listen_port)
  @log_label "UDP"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    {:ok, socket} = :gen_udp.open(@listen_port, [:binary])
    Logger.info("Listening on port #{@listen_port}", label: @log_label)

    state = %{
      socket: socket
    }

    {:ok, state}
  end

  def handle_info({:udp, socket, address, port, data}, state) do
    Logger.debug("Incoming command: #{inspect(data)}, from: #{inspect(address)}:#{inspect(port)}", label: @log_label)

    case Commands.new_command(data) do
      {:ok, command} ->
        Commands.send(command)
        send_ack(socket, address, port)

      Logger.debug("Valid command: #{inspect(command)}", label: @log_label)

      {:error, _error} ->
        case Commands.new_event(data) do
          {:ok, event} ->
            Commands.send(event)
            send_ack(socket, address, port)

          Logger.debug("Valid event: #{inspect(event)}", label: @log_label)

          {:error, error} ->
            Logger.debug("Inalid command or event: #{inspect(data)}, Error: #{inspect(error)}", label: @log_label)
        end
    end

    {:noreply, state}
  end

  def handle_info(other, state) do
    Logger.warn(" Unexpected message: #{inspect(other)}", label: @log_label)
    {:noreply, state}
  end

  def send_ack(socket, address, port) do
    :gen_udp.send(socket, address, port, <<42>>)
  end
end

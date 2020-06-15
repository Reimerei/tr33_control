defmodule Tr33Control.Commands.UART do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Event, Command}

  # these values have to match with the config in the firmware
  @baudrate 921_600
  # @baudrate 1_000_000
  @serial_header 42
  @serial_ready_to_send "AA" |> Base.decode16!()
  @serial_clear_to_send "BB" |> Base.decode16!()
  @serial_request_resync "CC" |> Base.decode16!()
  @command_data_bytes 10
  @command_batch_max_byte_size 1024
  @command_batch_max_command_count min(floor((@command_batch_max_byte_size - 2) / (@command_data_bytes + 2)), 256)
  @rts_max_wait_ms 100
  @debug_logs Application.get_env(:tr33_control, :uart_debug, false)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send(struct) do
    binary = to_binary(struct)
    GenServer.cast(__MODULE__, {:send, binary})
    struct
  end

  def send_rts() do
    GenServer.cast(__MODULE__, :send_rts)
  end

  def resync() do
    binaries =
      (Commands.list_commands() ++ Commands.list_events())
      |> Enum.map(&to_binary/1)

    GenServer.cast(__MODULE__, {:resync, binaries})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(_) do
    {:ok, uart_pid} = Nerves.UART.start_link()

    serial_port = Application.fetch_env!(:tr33_control, :serial_port)
    result = Nerves.UART.open(uart_pid, serial_port, speed: @baudrate, active: true)
    Logger.info("Connection to serial port #{serial_port}, baudrate: #{@baudrate}. Result: #{inspect(result)}")

    :ok = Nerves.UART.configure(uart_pid, framing: Nerves.UART.Framing.None)

    state = %{
      uart_pid: uart_pid,
      queue: :queue.new(),
      last_rts: 0
    }

    resync()
    {:ok, state}
  end

  def handle_cast({:send, binary}, %{queue: queue} = state) do
    state = send_rts(state, false)
    {:noreply, %{state | queue: :queue.in(binary, queue)}}
  end

  def handle_cast(:send_rts, state) do
    send_rts(state, true)
    {:noreply, state}
  end

  def handle_cast({:resync, binaries}, state) do
    state = send_rts(state, true)
    {:noreply, %{state | queue: :queue.from_list(binaries)}}
  end

  def handle_info({:nerves_uart, _, @serial_clear_to_send}, %{queue: queue} = state) do
    if @debug_logs do
      Logger.debug("UART RECEIVED CTS")
    end

    state = %{state | last_rts: 0}

    command_count = min(:queue.len(queue), @command_batch_max_command_count)
    {queue_send, queue_rest} = :queue.split(command_count, queue)
    header = <<@serial_header::size(8), command_count::size(8)>>

    if @debug_logs do
      Logger.debug("UART SENDING BATCH WITH #{inspect(command_count)} COMMANDS")
    end

    command_binaries =
      :queue.to_list(queue_send)
      |> Enum.map(&pad/1)

    packet = :erlang.iolist_to_binary([header | command_binaries])
    send_packet(state, packet)

    state =
      case :queue.len(queue_rest) do
        0 -> state
        _ -> send_rts(state, true)
      end

    {:noreply, %{state | queue: queue_rest}}
  end

  def handle_info({:nerves_uart, _, bytes}, state) do
    left_size = (byte_size(bytes) - 1) * 8

    case bytes do
      <<_::size(left_size), @serial_request_resync>> ->
        Logger.debug("UART RECEIVED RESYNC REQUEST")
        resync()

      _ ->
        Logger.warn("UART RECEIVED UNEXPECTED: #{inspect(bytes)}")
        :noop
    end

    {:noreply, state}
  end

  defp to_binary(%Command{} = command), do: Command.to_binary(command)
  defp to_binary(%Event{} = event), do: Event.to_binary(event)

  defp send_packet(%{uart_pid: uart_pid}, paket) do
    if @debug_logs do
      Logger.debug("UART SENDING #{inspect(paket)}")
    end

    :ok = Nerves.UART.write(uart_pid, paket)
  end

  # TODO: remove padding
  defp pad(binary) when is_binary(binary) do
    padding_size = (@command_data_bytes + 2 - byte_size(binary)) * 8
    <<binary::binary, 0::size(padding_size)>>
  end

  defp send_rts(state, true), do: do_send_rts(state)

  defp send_rts(%{last_rts: last_rts} = state, false) do
    if System.os_time(:millisecond) > last_rts + @rts_max_wait_ms do
      do_send_rts(state)
    else
      state
    end
  end

  defp do_send_rts(%{uart_pid: uart_pid} = state) do
    if @debug_logs do
      Logger.debug("UART SENDING RTS")
    end

    Nerves.UART.write(uart_pid, @serial_ready_to_send)
    %{state | last_rts: System.os_time(:millisecond)}
  end
end

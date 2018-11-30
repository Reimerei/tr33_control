defmodule Tr33Control.Commands.UART do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Event, Command, Cache}

  @baudrate 230_400
  @serial_port Application.fetch_env!(:tr33_control, :serial_port)
  @serial_header "42" |> Base.decode16!()
  @serial_ready_to_send "AA" |> Base.decode16!()
  @serial_clear_to_send "BB" |> Base.decode16!()
  @serial_request_resync "CC" |> Base.decode16!()
  @command_size 2 + 8

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send(struct) do
    binary = to_binary(struct)
    GenServer.cast(__MODULE__, {:send, binary})
    struct
  end

  def resync() do
    binaries =
      Cache.all()
      |> Enum.map(&to_binary/1)

    GenServer.cast(__MODULE__, {:resync, binaries})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(_) do
    {:ok, uart_pid} = Nerves.UART.start_link()

    result = Nerves.UART.open(uart_pid, @serial_port, speed: @baudrate, active: true)
    Logger.info("Connection to serial port #{@serial_port}, baudrate: #{@baudrate}. Result: #{inspect(result)}")

    :ok = Nerves.UART.configure(uart_pid, framing: Nerves.UART.Framing.None)

    state = %{
      uart_pid: uart_pid,
      queue: :queue.new()
    }

    {:ok, state}
  end

  def handle_cast({:send, binary}, %{queue: queue} = state) do
    send_rts(state)
    {:noreply, %{state | queue: :queue.in(binary, queue)}}
  end

  def handle_cast({:resync, binaries}, state) do
    send_rts(state)
    {:noreply, %{state | queue: :queue.from_list(binaries)}}
  end

  def handle_info({:nerves_uart, _, @serial_clear_to_send}, %{uart_pid: uart_pid, queue: queue} = state) do
    Logger.debug("UART RECEIVED CTS")
    {head, rest} = :queue.out(queue)
    send_binary(state, head)

    if :queue.len(rest) > 0, do: send_rts(state)

    {:noreply, %{state | queue: rest}}
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

  defp send_binary(%{uart_pid: uart_pid}, {:value, binary}) when byte_size(binary) < @command_size do
    padding_size = (@command_size - byte_size(binary)) * 8
    package = <<@serial_header, binary::binary, 0::size(padding_size)>>
    Logger.debug("UART SENDING #{inspect(package)}")
    :ok = Nerves.UART.write(uart_pid, package)
  end

  defp send_binary(_, value) do
    Logger.error("UART CANT SEND #{inspect(value)}")
  end

  defp send_rts(%{uart_pid: uart_pid}) do
    Logger.debug("UART SENDING RTS")
    Nerves.UART.write(uart_pid, @serial_ready_to_send)
  end
end

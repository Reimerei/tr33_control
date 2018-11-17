defmodule Tr33Control.Commands.UART do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Event, Command, Cache}

  @baudrate 230_400
  @serial_port Application.fetch_env!(:tr33_control, :serial_port)

  # @serial_port "ttyAMA0"

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
      (Cache.all_commands() ++ Cache.all_events())
      |> Enum.map(&to_binary/1)

    GenServer.cast(__MODULE__, {:resync, binaries})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(_) do
    {:ok, uart_pid} = Nerves.UART.start_link()

    result = Nerves.UART.open(uart_pid, @serial_port, speed: @baudrate, active: true)
    Logger.debug("Connection to serial port #{@serial_port}, baudrate: #{@baudrate}. Result: #{inspect(result)}")

    :ok = Nerves.UART.configure(uart_pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})

    state = %{
      uart_pid: uart_pid,
      queue: :queue.new()
    }

    {:ok, state}
  end

  def handle_cast({:send, binary}, %{queue: queue} = state) do
    {:noreply, %{state | queue: :queue.in(binary, queue)}}
  end

  def handle_cast({:resync, binaries}, state) do
    {:noreply, %{state | queue: :queue.from_list(binaries)}}
  end

  def handle_info({:nerves_uart, _, "OK"}, %{uart_pid: uart_pid, queue: queue} = state) do
    {head, rest} = :queue.out(queue)
    package = to_package(head)
    :ok = Nerves.UART.write(uart_pid, package)

    if byte_size(package) > 1 do
      Logger.debug("UART OK: sending package #{inspect(package)}")
    end

    {:noreply, %{state | queue: rest}}
  end

  def handle_info({:nerves_uart, _, "INIT"}, state) do
    resync()
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _, msg}, state) do
    Logger.debug("UART RECEIVED: #{inspect(msg)}")
    {:noreply, state}
  end

  def to_binary(%Command{} = command), do: Command.to_binary(command)
  def to_binary(%Event{} = event), do: Event.to_binary(event)

  def to_package(:empty), do: <<0::size(8)>>
  def to_package({:value, binary}), do: <<byte_size(binary)::size(8), binary::binary>>
end

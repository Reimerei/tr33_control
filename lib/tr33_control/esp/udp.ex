defmodule Tr33Control.ESP.UDP do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @tick_interval_ms 50
  @max_queue_len 1000 / 25
  @udp_registry :udp_targets
  @target_port 1337

  def start_link({target, process_name}) when is_atom(target) do
    GenServer.start_link(__MODULE__, target, name: process_name)
  end

  def send(binary, process_name) when is_binary(binary) do
    GenServer.cast(process_name, {:send, binary})
  end

  def toggle_debug() do
    current = Application.get_env(:tr33_control, :udp_debug, false)
    Application.put_env(:tr33_control, :udp_debug, not current)
  end

  def init(target) do
    host = "#{target}.#{Application.fetch_env!(:tr33_control, :local_domain)}" |> String.to_charlist()

    case :inet.gethostbyname(host, :inet) do
      {:ok, {:hostent, _host, [], :inet, 4, [{192, _, _, _} = ip | _]}} ->
        Logger.info(
          "#{__MODULE__}: Resovled host #{host} to #{inspect(ip)}. Sending UDP commands to port #{@target_port}"
        )

        {:ok, socket} = :gen_udp.open(Enum.random(5000..65535), [:binary])

        state = %{
          socket: socket,
          last_packet: System.os_time(:millisecond),
          queue: :queue.new(),
          host: host,
          sequence: 0
        }

        :timer.send_interval(@tick_interval_ms, :tick)

        {:ok, _} = Registry.register(@udp_registry, ip, target)

        Commands.subscribe()

        {:ok, state}

      other ->
        debug_log("Could not resolve host name #{host}. Not sending UDP commands. Reason: #{inspect(other)}")
        :ignore
    end
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

  def handle_info({:command_update, %Command{} = command}, %{queue: queue} = state) do
    state =
      if :queue.len(queue) < @max_queue_len do
        %{state | queue: :queue.in(command.encoded, queue)}
      else
        state
      end

    {:noreply, state}
  end

  def handle_info(:tick, %{queue: queue} = state) do
    state =
      case :queue.out(queue) do
        {:empty, _} ->
          state

        {{:value, binary}, rest} ->
          # todo: send multiple commands in one packet
          state = transmit_binary(binary, state)
          %{state | queue: rest}
      end

    {:noreply, state}
  end

  defp transmit_binary(binary, state = %{socket: socket, host: host}) when is_binary(binary) do
    result = :gen_udp.send(socket, host, @target_port, binary)

    "Send packet to #{inspect(host)} result: #{inspect(result)} content: #{inspect(binary)}"
    |> debug_log()

    state
  end

  def debug_log(message) do
    if Application.get_env(:tr33_control, :udp_debug, false) do
      Logger.debug("#{__MODULE__}: #{message}")
    end
  end
end

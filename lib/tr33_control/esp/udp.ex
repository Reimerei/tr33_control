defmodule Tr33Control.ESP.UDP do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @tick_interval_ms 50
  @max_queue_len 1000 / 25
  @udp_registry :udp_targets
  @target_port 1337

  def start_link({target, host, process_name}) when is_atom(target) do
    GenServer.start_link(__MODULE__, {target, host}, name: process_name)
  end

  def toggle_debug() do
    current = Application.get_env(:tr33_control, :udp_debug, false)
    Application.put_env(:tr33_control, :udp_debug, not current)
  end

  def init({target, host}) do
    case host |> String.to_charlist() |> :inet.gethostbyname(:inet) do
      {:ok, {:hostent, _host, [], :inet, 4, [{192, _, _, _} = ip | _]}} ->
        Logger.info(
          "#{__MODULE__}: Resovled host #{host} for target #{inspect(target)} to #{inspect(ip)}. Sending UDP commands to port #{@target_port}"
        )

        {:ok, socket} = :gen_udp.open(Enum.random(5000..65535), [:binary])

        state =
          %{
            socket: socket,
            last_packet: System.os_time(:millisecond),
            queue: :queue.new(),
            target: target,
            host: host,
            ip: ip,
            sequence: 0
          }
          |> resync_queue()

        :timer.send_interval(@tick_interval_ms, :tick)

        {:ok, _} = Registry.register(@udp_registry, ip, target)

        Commands.subscribe()

        {:ok, state}

      other ->
        debug_log("Could not resolve host name #{host}. Not sending UDP commands. Reason: #{inspect(other)}")
        :ignore
    end
  end

  def handle_info({:command_update, %Command{} = command}, %{target: target} = state) do
    state =
      command
      |> Commands.binary_for_target(target)
      |> maybe_enqueue(state)

    {:noreply, state}
  end

  def handle_info(:resync, state) do
    {:noreply, resync_queue(state)}
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

  def handle_info(_, state), do: {:noreply, state}

  defp maybe_enqueue(binary, %{queue: queue} = state) do
    if :queue.len(queue) < @max_queue_len do
      %{state | queue: :queue.in(binary, queue)}
    else
      state
    end
  end

  defp resync_queue(state) do
    debug_log("Enqueuing resync commands for #{inspect(state.host)}")

    queue =
      Commands.list_commands()
      |> Enum.reduce(:queue.new(), fn %Command{encoded: encoded}, queue_acc -> :queue.in(encoded, queue_acc) end)

    %{state | queue: queue}
  end

  defp transmit_binary(binary, state = %{socket: socket, host: host}) when is_binary(binary) do
    "Sending packet to #{inspect(host)} content: #{inspect(binary)}"
    |> debug_log()

    result = :gen_udp.send(socket, String.to_charlist(host), @target_port, binary)

    "Send Result: #{inspect(result)}"
    |> debug_log()

    state
  end

  def debug_log(message) do
    if Application.get_env(:tr33_control, :udp_debug, false) do
      Logger.debug("#{__MODULE__}: #{message}")
    end
  end
end

defmodule Tr33Control.Commands.Socket do
  use GenServer
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @host {192, 168, 0, 42}
  @port 1337
  @idle_period_ms 50
  @refresh_after_idle_ms 150
  @poll_interval_ms 250
  @cache_persist_interval_ms 1_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, [{:name, __MODULE__} | opts])
  end

  def send_command(%Command{} = command) do
    GenServer.cast(__MODULE__, {:send_command, command})
  end

  # -- GenServer callbacks -----------------------------------------------------

  def init(:ok) do
    local_port = Enum.random(5000..65535)
    {:ok, socket} = :gen_udp.open(local_port, [:binary])
    schedule_poll()
    now = System.os_time(:milliseconds)
    {:ok, %{socket: socket, last_command: now, refresh_index: 0, last_persist: now}}
  end

  def handle_cast({:send_command, command}, state) do
    %{socket: socket, last_command: last_command} = state

    if System.os_time(:milliseconds) > last_command + @idle_period_ms do
      result = do_send_command(command, socket)
      {:noreply, %{state | last_command: System.os_time(:milliseconds)}}
    else
      {:noreply, state}
    end
  end

  def handle_info(:poll, state) do
    state =
      state
      |> maybe_refresh()
      |> maybe_persist_cache()

    schedule_poll()

    {:noreply, state}
  end

  defp do_send_command(command, socket) do
    packet =
      command
      |> Command.to_binary()

    Logger.info("Send packet to #{inspect(@host)}:#{@port} data: #{inspect(packet)}")
    :ok = :gen_udp.send(socket, @host, @port, packet)
  end

  defp schedule_poll() do
    Process.send_after(self(), :poll, @poll_interval_ms)
  end

  defp maybe_refresh(%{refresh_index: index, last_command: last_command} = state) do
    now = System.os_time(:milliseconds)

    if now > last_command + @refresh_after_idle_ms do
      case Commands.cache_get(index) do
        nil ->
          %{state | refresh_index: 0}

        %Command{} = command ->
          send_command(command)
          %{state | refresh_index: index + 1}
      end
    else
      state
    end
  end

  defp maybe_persist_cache(%{last_persist: last_persist} = state) do
    now = System.os_time(:milliseconds)

    if now > last_persist + @cache_persist_interval_ms do
      Commands.cache_persist()
      %{state | last_persist: now}
    else
      state
    end
  end
end

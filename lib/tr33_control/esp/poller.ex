defmodule Tr33Control.ESP.Poller do
  use GenServer
  require Logger
  alias Tr33Control.ESP

  @tick_interval 60_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    # ESP.resync()
    ESP.connect_udp()

    {:noreply, state}
  end
end

defmodule Tr33Control.ESP.Syncer do
  use GenServer
  require Logger
  alias Tr33Control.ESP

  @resync_interval 60000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    :timer.send_interval(@resync_interval, :resync)
    {:ok, %{}}
  end

  def handle_info(:resync, state) do
    ESP.resync()
    {:noreply, state}
  end
end

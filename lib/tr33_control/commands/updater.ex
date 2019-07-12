defmodule Tr33Control.Commands.Updater do
  use GenServer
  require Logger

  alias Tr33Control.Commands

  @update_interval_ms 15

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    do_update()
    {:ok, %{}}
  end

  def handle_info(:update, state) do
    do_update()
    {:noreply, state}
  end

  defp do_update() do
    # Commands.list_commands()
    # |> Enum.each(&Commands.apply_modifiers/1)

    Process.send_after(self(), :update, @update_interval_ms)
  end
end

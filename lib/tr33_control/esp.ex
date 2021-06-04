defmodule Tr33Control.ESP do
  use Supervisor
  require Logger

  alias Tr33Control.ESP.{UDP, UART}

  @udp_registry :udp_targets

  ### Supervisor ##############################################

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def children() do
    Supervisor.which_children(__MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      [
        {Registry, [keys: :unique, name: @udp_registry]},
        Tr33Control.ESP.Poller
        # UART
      ] ++ udp_children()

    Supervisor.init(children, strategy: :one_for_one)
  end

  ### External API ###########################################

  def resync(address, _port) do
    try_reconnect()

    case Registry.lookup(@udp_registry, address) do
      [{pid, _target}] ->
        send(pid, :resync)

      _ ->
        Logger.warn("#{__MODULE__}: Could not resync because #{inspect(address)} has no registered UDP process")
        :noop
    end
  end

  def try_reconnect() do
    for %{id: child_id} <- udp_children() do
      Supervisor.restart_child(__MODULE__, child_id)
    end
  end

  ### Helper ##########################################

  defp process_name(host) do
    {:via, Registry, {@udp_registry, host}}
  end

  def udp_children() do
    Application.fetch_env!(:tr33_control, :target_hosts)
    |> Enum.flat_map(fn {target, hosts} -> Enum.map(hosts, &{target, &1}) end)
    |> Enum.map(fn {target, host} ->
      %{
        id: host,
        start: {UDP, :start_link, [{target, host, process_name(host)}]}
      }
    end)
  end
end

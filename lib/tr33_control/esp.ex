defmodule Tr33Control.ESP do
  use Supervisor
  require Logger

  alias Tr33Control.ESP.{UDP, UART}
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Modifier}

  @udp_registry :udp_targets
  @wolken_targets [:wolke1, :wolke2, :wolke3, :wolke4, :wolke5, :wolke6, :wolke7, :wolke8]
  @udp_targets [:trommel, :wand] ++ @wolken_targets
  @uart_targets [:uart]
  @all_targets @udp_targets ++ @uart_targets
  @group_targets [:all, :wolken]
  @transmitted_modifier_count 8

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

  # def sync_modifiers(targets \\ @all_targets) do
  #   disabled_modifier = %Modifier{index: 0, data_index: 0}

  #   modifiers_to_transmit =
  #     Commands.list_modifiers()
  #     |> Enum.sort_by(fn %Modifier{index: index, data_index: data_index} -> {index, data_index} end)
  #     |> Enum.take(@transmitted_modifier_count)
  #     |> Enum.map(&add_modifier_target/1)
  #     |> fill_list(@transmitted_modifier_count, {disabled_modifier, :all})

  #   for target <- targets do
  #     binary =
  #       Enum.map(modifiers_to_transmit, fn {modifier, modifier_target} ->
  #         if target_match?(modifier_target, target) do
  #           modifier
  #         else
  #           disabled_modifier
  #         end
  #       end)
  #       |> Enum.map(&Modifier.to_binary/1)
  #       |> :erlang.iolist_to_binary()

  #     <<0::size(8), 106::size(8), binary::binary>>
  #     |> send_to_target(target)
  #   end
  # end

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

  defp fill_list(list, count, _) when length(list) == count, do: list

  defp fill_list(list, count, item) do
    added = for _ <- 0..(count - length(list)), do: item
    list ++ added
  end

  defp add_modifier_target(%Modifier{index: index} = modifier) do
    # todo
    # %Command{target: target} = Commands.get_command(index)
    # {modifier, target}
  end

  defp target_match?(:all, _), do: true
  defp target_match?(:wolken, target) when target in @wolken_targets, do: true
  defp target_match?(target, target), do: true
  defp target_match?(_, _), do: false

  defp active_upd_targets() do
    children()
    |> Enum.filter(&match?({_id, _pid, _type, [Tr33Control.ESP.UDP]}, &1))
    |> Enum.reject(&match?({_id, :undefined, _type, _}, &1))
    |> Enum.map(fn {target, _pid, _type, _} -> target end)
  end
end

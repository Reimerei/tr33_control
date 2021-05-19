defmodule Tr33Control.ESP do
  use Supervisor

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
    udp_children = Enum.map(@udp_targets, &udp_child_spec/1)

    children =
      [
        {Registry, [keys: :unique, name: @udp_registry]},
        Tr33Control.ESP.Poller,
        UART
      ] ++ udp_children

    Supervisor.init(children, strategy: :one_for_one)
  end

  ### External API ###########################################

  def send(struct), do: do_send(struct, @all_targets)

  def sync_modifiers(targets \\ @all_targets) do
    disabled_modifier = %Modifier{index: 0, data_index: 0}

    modifiers_to_transmit =
      Commands.list_modifiers()
      |> Enum.sort_by(fn %Modifier{index: index, data_index: data_index} -> {index, data_index} end)
      |> Enum.take(@transmitted_modifier_count)
      |> Enum.map(&add_modifier_target/1)
      |> fill_list(@transmitted_modifier_count, {disabled_modifier, :all})

    for target <- targets do
      binary =
        Enum.map(modifiers_to_transmit, fn {modifier, modifier_target} ->
          if target_match?(modifier_target, target) do
            modifier
          else
            disabled_modifier
          end
        end)
        |> Enum.map(&Modifier.to_binary/1)
        |> :erlang.iolist_to_binary()

      <<0::size(8), 106::size(8), binary::binary>>
      |> send_to_target(target)
    end
  end

  def resync(targets \\ @all_targets) do
    (Commands.list_commands() ++ Commands.list_events())
    |> Enum.map(&do_send(&1, targets))

    sync_modifiers(targets)
  end

  def resync(address, _port) do
    try_reconnect()

    case Registry.lookup(@udp_registry, address) do
      [{_pid, target}] -> resync([target])
      _ -> :noop
    end
  end

  def toggle_target(target) do
    list = @group_targets ++ @uart_targets ++ active_upd_targets()

    case Enum.find_index(list, &match?(^target, &1)) do
      nil ->
        :all

      index ->
        case Enum.at(list, index + 1) do
          nil -> List.first(list)
          new_target -> new_target
        end
    end
  end

  def try_reconnect() do
    for %{id: child_id} <- Enum.map(@udp_targets, &udp_child_spec/1) do
      Supervisor.restart_child(__MODULE__, child_id)
    end
  end

  ### Helper ##########################################

  defp do_send(%Command{index: index} = command, targets) do
    # todo
    # binary = Command.to_binary(command)
    # disable_binary = Command.defaults(index) |> Command.to_binary()

    # for target <- targets do
    #   if target_match?(command_target, target) do
    #     send_to_target(binary, target)
    #   else
    #     send_to_target(disable_binary, target)
    #   end
    # end

    # command
  end

  defp do_send(%Event{} = event, targets) do
    binary = Event.to_binary(event)

    for target <- targets do
      send_to_target(binary, target)
    end

    event
  end

  defp process_name(udp_target) do
    {:via, Registry, {@udp_registry, udp_target}}
  end

  def udp_child_spec(udp_target) do
    %{
      id: udp_target,
      start: {UDP, :start_link, [{udp_target, process_name(udp_target)}]}
    }
  end

  defp send_to_target(binary, :uart) when is_binary(binary) do
    UART.send(binary)
  end

  defp send_to_target(binary, target) when is_binary(binary) and is_atom(target) do
    UDP.send(binary, process_name(target))
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

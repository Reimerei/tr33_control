defmodule Tr33Control.ESP do
  use Supervisor

  alias Tr33Control.ESP.{UDP, UART}
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Modifier}

  @udp_registry :esp_targets
  @wolken_targets [:wolke1, :wolke2, :wolke3]
  # @udp_targets [:trommel] ++ @wolken_targets
  # @all_targets [:uart] ++ @udp_targets
  @udp_targets [:wand]
  @all_targets @udp_targets
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
        # Tr33Control.ESP.Syncer,
        UART
      ] ++ udp_children

    Supervisor.init(children, strategy: :one_for_one)
  end

  ### External API ###########################################

  def send(%Command{target: command_target, index: index} = command) do
    binary = Command.to_binary(command)
    disable_binary = Command.defaults(index) |> Command.to_binary()

    for target <- @all_targets do
      if target_match?(command_target, target) do
        send_to_target(binary, target)
      else
        send_to_target(disable_binary, target)
      end
    end

    command
  end

  def send(%Event{} = event) do
    binary = Event.to_binary(event)

    for target <- @all_targets do
      send_to_target(binary, target)
    end

    event
  end

  def sync_modifiers() do
    disabled_modifier = %Modifier{index: 0, data_index: 0}

    modifiers_to_transmit =
      Commands.list_modifiers()
      |> Enum.sort_by(fn %Modifier{index: index, data_index: data_index} -> {index, data_index} end)
      |> Enum.take(@transmitted_modifier_count)
      |> Enum.map(&add_modifier_target/1)
      |> fill_list(@transmitted_modifier_count, {disabled_modifier, :all})

    for target <- @udp_targets do
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

  def resync() do
    (Commands.list_commands() ++ Commands.list_events())
    |> Enum.map(&send/1)

    sync_modifiers()
  end

  def toggle_target(target) do
    list = [:all, :wolken] ++ @all_targets

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

  ### Helper ##########################################

  defp process_name(udp_target) do
    {:via, Registry, {@udp_registry, udp_target}}
  end

  def udp_child_spec(udp_target) do
    %{
      id: make_ref(),
      start: {UDP, :start_link, [{host_for_target(udp_target), 1337, process_name(udp_target)}]}
    }
  end

  defp send_to_target(binary, :uart) when is_binary(binary) do
    UART.send(binary)
  end

  defp send_to_target(binary, target) when is_binary(binary) and is_atom(target) do
    UDP.send(binary, process_name(target))
  end

  defp host_for_target(:wand), do: "wand.fritz.box"
  # defp host_for_target(:neo), do: "192.168.0.200"
  # defp host_for_target(other), do: "#{other}.fritz.box"
  defp host_for_target(other), do: "#{other}.lan.xhain.space"

  defp fill_list(list, count, _) when length(list) == count, do: list

  defp fill_list(list, count, item) do
    added = for _ <- 0..(count - length(list)), do: item
    list ++ added
  end

  defp add_modifier_target(%Modifier{index: index} = modifier) do
    %Command{target: target} = Commands.get_command(index)
    {modifier, target}
  end

  defp target_match?(:all, _), do: true
  defp target_match?(:wolken, target) when target in @wolken_targets, do: true
  defp target_match?(target, target), do: true
  defp target_match?(_, _), do: false
end

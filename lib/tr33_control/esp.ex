defmodule Tr33Control.ESP do
  use Supervisor

  alias Tr33Control.ESP.{UDP, UART}
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event}

  @udp_registry :esp_targets
  # @udp_targets [:trommel, :wolke4, :wolke6]
  # @all_targets [:uart] ++ @udp_targets
  @udp_targets [:wand, :neo]
  @all_targets @udp_targets

  ### External API ###########################################

  def send(%Command{target: :all} = command) do
    binary = Command.to_binary(command)

    for target <- @all_targets do
      send_to_target(binary, target)
    end

    command
  end

  def send(%Command{target: target, index: index} = command) do
    binary = Command.to_binary(command)
    disable_binary = Command.defaults(index) |> Command.to_binary()

    Enum.each(@all_targets, fn
      ^target -> send_to_target(binary, target)
      other_target -> send_to_target(disable_binary, other_target)
    end)

    command
  end

  def send(%Event{} = event) do
    binary = Event.to_binary(event)

    for target <- @all_targets do
      send_to_target(binary, target)
    end

    event
  end

  def resync() do
    (Commands.list_commands() ++ Commands.list_events())
    |> Enum.map(&send/1)
  end

  def toggle_target(target) do
    list = [:all | @all_targets]

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
        Tr33Control.ESP.Syncer
        # UART
      ] ++ udp_children

    Supervisor.init(children, strategy: :one_for_one)
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
  defp host_for_target(:neo), do: "192.168.0.200"
  defp host_for_target(other), do: "#{other}.fritz.box"
  # defp host_for_target(other), do: "#{other}.lan.xhain.space"
end

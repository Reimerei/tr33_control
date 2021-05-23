defmodule Tr33Control.Commands do
  alias __MODULE__.{ProtoBuf, Command, Cache, ValueParam}

  @default_command_type ProtoBuf.SingleColorCommand
  @command_targets Application.compile_env!(:tr33_control, :command_targets)
  @pubsub_topic "#{inspect(__MODULE__)}"

  def init() do
    Cache.init_all()

    # todo
    # default_preset()
    # |> load_preset
  end

  ### PubSub #######################################################################

  def subscribe() do
    Phoenix.PubSub.subscribe(Tr33Control.PubSub, @pubsub_topic)
  end

  def notify_subscribers(%Command{} = command) do
    pubsub_broadcast({:command_update, command})
    command
  end

  defp pubsub_broadcast(message), do: Phoenix.PubSub.broadcast!(Tr33Control.PubSub, @pubsub_topic, message)

  ### Commands ########################################################################################################

  def command_types() do
    ProtoBuf.defs()
    |> Enum.filter(&match?({{:msg, _}, _}, &1))
    |> Enum.map(fn {{_, type}, _} -> type end)
    |> List.delete(ProtoBuf.CommonParams)
  end

  def get_command(index) do
    Cache.get(Command, index)
  end

  def list_commands() do
    Cache.all(Command)
  end

  def create_command(index, type \\ @default_command_type) when is_atom(type) and is_number(index) do
    common = apply(ProtoBuf.CommonParams, :new, [[index: index]])

    %Command{
      index: index,
      params: apply(type, :new, [[common: common]])
    }
    |> process_command()
  end

  def delete_command(index) do
    Cache.delete(Command, index)
  end

  def update_command_param(index, name, value) do
    command = %Command{} = get_command(index)

    new_params = Map.replace!(command.params, name, value)

    %Command{command | params: new_params}
    |> process_command()
  end

  def update_command_common_param(index, name, value) do
    command = %Command{} = get_command(index)

    new_common = Map.replace!(command.params.common, name, value)

    %Command{command | params: %{command.params | common: new_common}}
    |> process_command()
  end

  def toggle_command_enabled(index) do
    command = %Command{} = get_command(index)

    %Command{command | enabled: !command.enabled}
    |> process_command()
  end

  def toggle_command_target(index, target) when target in @command_targets do
    command = %Command{} = get_command(index)

    new_targets =
      if Enum.member?(command.targets, target) do
        List.delete(command.targets, target)
      else
        [target | command.targets]
      end

    %Command{command | targets: new_targets}
    |> process_command()
  end

  def count_commands() do
    Cache.count(Command)
  end

  ### Command Params ###############################################################################

  def list_value_params(%Command{} = command) do
    ValueParam.list(command)
  end

  def list_enum_params(%Command{} = command) do
    EnumParam.list(command)
  end

  def get_common_param(%Command{} = command, name) do
    ValueParam.get_common(command, name)
  end

  ### Helpers ###################################################################################

  defp process_command(%Command{} = command) do
    command
    |> Command.encode()
    |> Cache.insert()
    |> notify_subscribers()
  end
end

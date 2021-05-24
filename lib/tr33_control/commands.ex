defmodule Tr33Control.Commands do
  alias __MODULE__.{Schemas, Command, Cache, ValueParam, EnumParam}

  @default_command_type Schemas.SingleColorCommand
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
    Schemas.defs()
    |> Enum.filter(&match?({{:msg, _}, _}, &1))
    |> Enum.map(fn {{_, type}, _} -> type end)
    |> List.delete(Schemas.CommonParams)
  end

  def get_command(index) do
    Cache.get(Command, index)
  end

  def list_commands() do
    Cache.all(Command)
  end

  def create_command(index, type \\ @default_command_type) when is_atom(type) and is_number(index) do
    common = apply(Schemas.CommonParams, :new, [[index: index]])

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
    Command.list_field_defs(command)
    |> Enum.map(&ValueParam.new(command.params, &1))
    |> Enum.reject(&is_nil/1)
  end

  def list_enum_params(%Command{} = command) do
    Command.list_field_defs(command)
    |> Enum.map(&EnumParam.new(command.params, &1))
    |> Enum.reject(&is_nil/1)
  end

  def get_common_value_param(%Command{} = command, name) do
    Command.get_common_field_def(name)
    |> then(&ValueParam.new(command.params.common, &1))
  end

  def get_common_enum_param(%Command{} = command, name) do
    Command.get_common_field_def(name)
    |> then(&EnumParam.new(command.params.common, &1))
  end

  ### Helpers ###################################################################################

  defp process_command(%Command{} = command) do
    command
    |> Command.encode()
    |> Cache.insert()
    |> notify_subscribers()
  end
end

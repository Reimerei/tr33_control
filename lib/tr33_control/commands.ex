defmodule Tr33Control.Commands do
  alias __MODULE__.{Schemas, Command, Cache, ValueParam, EnumParam}
  alias __MODULE__.Schemas.CommandParams

  @default_command_type :single_color
  @command_targets Application.compile_env!(:tr33_control, :command_targets)
  @pubsub_topic "#{inspect(__MODULE__)}"
  @common_params %CommandParams{} |> Map.from_struct() |> Map.delete(:type_params) |> Map.keys()

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
    %Protobuf.OneOfField{fields: fields} = Schemas.CommandParams.defs(:field, :type_params)

    fields
    |> Enum.map(fn %Protobuf.Field{name: name} -> name end)
  end

  def get_command(index) do
    Cache.get(Command, index)
  end

  def list_commands() do
    Cache.all(Command)
  end

  def create_command(index, type \\ @default_command_type) when is_atom(type) and is_number(index) do
    Command.new(index, type)
    |> process_command()
  end

  def delete_command(index) do
    Cache.delete(Command, index)
  end

  def update_command_param(index, name, value) when name in @common_params do
    command = %Command{} = get_command(index)

    new_params = Map.replace!(command.params, name, value)

    %Command{command | params: new_params}
    |> process_command()
  end

  def update_command_param(index, name, value) do
    command = %Command{} = get_command(index)

    type = Command.type(command)
    new_type_params = command |> Command.type_params() |> Map.replace!(name, value)
    new_params = %CommandParams{command.params | type_params: {type, new_type_params}}

    %Command{command | params: new_params}
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

  def binary_for_target(%Command{encoded: encoded, index: index, targets: targets}, target) do
    if target in targets do
      encoded
    else
      %Command{encoded: encoded} = Command.disabled(index)
      encoded
    end
  end

  ### Command Params: EnumParam + ValueParam ###############################################################################

  def list_value_params(%Command{} = command) do
    type_params = Command.type_params(command)

    Command.list_type_field_defs(command)
    |> Enum.map(&ValueParam.new(type_params, &1))
    |> Enum.reject(&is_nil/1)
  end

  def list_enum_params(%Command{} = command) do
    type_params = Command.type_params(command)

    Command.list_type_field_defs(command)
    |> Enum.map(&EnumParam.new(type_params, &1))
    |> Enum.reject(&is_nil/1)
  end

  def get_common_value_param(%Command{} = command, name) do
    Command.get_field_def(name)
    |> then(&ValueParam.new(command.params, &1))
  end

  def get_common_enum_param(%Command{} = command, name) do
    Command.get_field_def(name)
    |> then(&EnumParam.new(command.params, &1))
  end

  def list_common_params() do
    @common_params
  end

  ### Helpers ###################################################################################

  defp process_command(%Command{} = command) do
    command
    |> Command.encode()
    |> Cache.insert()
    |> notify_subscribers()
  end
end

defmodule Tr33Control.Commands do
  alias __MODULE__.{Schemas, Command, Cache, ValueParam, EnumParam, Preset}
  alias __MODULE__.Schemas.CommandParams

  @command_targets Application.compile_env!(:tr33_control, :targets)
  @pubsub_topic "#{inspect(__MODULE__)}"
  @common_params %CommandParams{} |> Map.from_struct() |> Map.delete(:type_params) |> Map.keys()

  def init() do
    Cache.init_all()

    case get_default_preset() do
      nil ->
        create_command(0, :rainbow)

      %Preset{name: name} ->
        load_preset(name)
    end
  end

  ### PubSub #######################################################################

  def subscribe() do
    Phoenix.PubSub.subscribe(Tr33Control.PubSub, @pubsub_topic)
  end

  def notify_subscribers(%Command{} = command) do
    pubsub_broadcast({:command_update, command})
    command
  end

  def notify_subscribers(%Preset{} = preset) do
    pubsub_broadcast({:preset_update, preset})
    preset
  end

  def notify_subscribers(:preset_deleted, name) do
    pubsub_broadcast({:preset_deleted, name})
  end

  def notify_subscribers(:command_deleted, index) do
    pubsub_broadcast({:command_deleted, index})
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
    |> Enum.sort_by(fn %Command{} = c -> c.index end)
  end

  def create_command(index, type, params \\ []) when is_atom(type) and is_number(index) and is_list(params) do
    Command.new(index, type, params)
    |> insert_and_push_command()
  end

  def create_command(protobuf) when is_binary(protobuf) do
    Command.new(protobuf)
    |> insert_and_push_command()
  end

  def create_disabled_command(index) do
    Command.disabled(index)
    |> insert_and_push_command()
  end

  def delete_command(index) do
    count = Cache.count(Command)

    if count > 1 do
      {_first, second} =
        Cache.all(Command)
        |> Enum.split(index)

      second
      |> tl()
      |> Enum.with_index(index)
      |> Enum.map(fn {%Command{} = command, new_index} ->
        %Command{command | index: new_index}
      end)
      |> Enum.map(&insert_and_push_command/1)

      create_disabled_command(index)
      Cache.delete(Command, count - 1)
      notify_subscribers(:command_deleted, index)
    end
  end

  def update_command_param(index, name, value) when name in @common_params do
    command = %Command{} = get_command(index)

    new_params = Map.replace!(command.params, name, value)

    %Command{command | params: new_params}
    |> insert_and_push_command()
  end

  def update_command_param(index, name, value) do
    command = %Command{} = get_command(index)

    type = Command.type(command)
    new_type_params = command |> Command.type_params() |> Map.replace!(name, value)
    new_params = %CommandParams{command.params | type_params: {type, new_type_params}}

    %Command{command | params: new_params}
    |> insert_and_push_command()
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
    |> insert_and_push_command()
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

  def get_strip_index_options(%Command{targets: [target]}) do
    Application.fetch_env!(:tr33_control, :target_strip_indices)
    |> Map.get(target, [])
    |> Enum.with_index()
  end

  def get_strip_index_options(%Command{}), do: []

  ### Presets ###############################################################################

  def create_preset(name) when is_binary(name) do
    %Preset{
      name: name,
      commands: list_commands()
    }
    |> Cache.insert()
    |> notify_subscribers()
  end

  def delete_preset(name) do
    Cache.delete(Preset, name)
    notify_subscribers({:preset_deleted, name})
  end

  def load_preset(name) do
    %Preset{commands: commands} = preset = Cache.get(Preset, name)

    previous_count = count_commands()
    new_count = Enum.count(commands)

    if previous_count > new_count do
      (previous_count - 1)..new_count
      |> Enum.map(&delete_command/1)
    end

    commands
    |> Enum.map(&insert_and_push_command/1)

    preset
  end

  def list_presets() do
    Cache.all(Preset)
  end

  def get_default_preset() do
    Cache.all(Preset)
    |> Enum.find(fn %Preset{} = preset -> preset.default end)
  end

  def set_default_preset(name) do
    get_default_preset()
    |> case do
      nil -> :noop
      preset -> %Preset{preset | default: false} |> Cache.insert()
    end

    load_preset(name)
    |> then(fn preset -> %Preset{preset | default: true} end)
    |> Cache.insert()
    |> notify_subscribers()
  end

  ### Helpers ###################################################################################

  defp insert_and_push_command(%Command{} = command) do
    command
    |> Command.encode()
    |> Cache.insert()
    |> notify_subscribers()
  end
end

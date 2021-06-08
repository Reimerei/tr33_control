defmodule Tr33Control.Commands do
  alias __MODULE__.{Schemas, Command, Cache, ValueParam, EnumParam, Preset}
  alias __MODULE__.Schemas.{CommandParams, Modifier}

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

  def list_commands(opts \\ []) do
    Cache.all(Command)
    |> Enum.sort_by(fn %Command{} = c -> c.index end)
    |> maybe_fill_commands(Keyword.get(opts, :include_empty))
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

  ### Modifiers ###################################################################################

  def list_modifier_names(%Command{} = command) do
    common =
      list_common_params()
      |> Enum.filter(&(&1 in [:brightness, :color_palette, :strip_index]))

    type =
      command
      |> list_value_params()
      |> Enum.map(fn %ValueParam{name: name} -> name end)

    common ++ type
  end

  def get_modifier_params(%Command{params: %CommandParams{modifiers: modifiers}} = command) do
    modifiers
    |> Enum.sort_by(fn %Modifier{field_index: i} -> i end)
    |> Enum.map(fn modifier ->
      name = modifier_name(command, modifier)

      field_defs = Command.list_modifier_field_defs()
      enum_params = Enum.map(field_defs, &EnumParam.new(modifier, &1)) |> Enum.reject(&is_nil/1)
      value_params = Enum.map(field_defs, &ValueParam.new(modifier, &1)) |> Enum.reject(&is_nil/1)

      {name, enum_params, value_params}
    end)
  end

  def get_modifier(%Command{params: %CommandParams{} = params}, field_index) when is_number(field_index) do
    params.modifiers
    |> Enum.find(&match?(%Modifier{field_index: ^field_index}, &1))
  end

  def get_modifier(%Command{} = command, name) when is_atom(name) do
    field_index = modifier_field_index(command, name)
    get_modifier(command, field_index)
  end

  def add_modifier(%Command{params: %CommandParams{} = params} = command, name) when is_atom(name) do
    field_index = modifier_field_index(command, name)

    case get_modifier(command, field_index) do
      nil ->
        modifiers = [%Modifier{field_index: field_index} | params.modifiers]
        update_command_param(command.index, :modifiers, modifiers)

      %Modifier{} ->
        command
    end
  end

  def update_modifier(%Command{params: %CommandParams{} = params} = command, name, fields) when is_map(fields) do
    field_index = modifier_field_index(command, name)

    modifiers =
      params.modifiers
      |> Enum.map(fn
        %Modifier{field_index: ^field_index} = modifier -> Map.merge(modifier, fields)
        modifier -> modifier
      end)

    update_command_param(command.index, :modifiers, modifiers)
  end

  def delete_modifier(%Command{params: %CommandParams{} = params} = command, name) when is_atom(name) do
    to_delete = get_modifier(command, name)

    modifiers =
      params.modifiers
      |> List.delete(to_delete)

    update_command_param(command.index, :modifiers, modifiers)
  end

  def modifier_name(%Command{} = command, %Modifier{field_index: field_index}) do
    command
    |> list_modifier_names()
    |> Enum.at(field_index)
  end

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
    notify_subscribers(:preset_deleted, name)
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

  defp modifier_field_index(%Command{} = command, name) do
    {_, index} =
      command
      |> list_modifier_names()
      |> Enum.with_index()
      |> Enum.find(&match?({^name, _}, &1))

    index
  end

  defp insert_and_push_command(%Command{} = command) do
    command
    |> Command.encode()
    |> Cache.insert()
    |> notify_subscribers()
  end

  defp maybe_fill_commands(commands, false), do: commands

  defp maybe_fill_commands(commands, true) do
    max = Application.fetch_env!(:tr33_control, :command_max_index)

    case Enum.count(commands) do
      ^max -> commands
      count -> commands ++ Enum.map(count..(max - 1), &create_disabled_command/1)
    end
  end
end

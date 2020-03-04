defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias __MODULE__
  alias Tr33Control.Commands.{Modifier, Inputs}
  alias Tr33Control.Commands.Inputs.{Select}

  defenum CommandType,
    disabled: 0,
    single_color: 1,
    white: 2,
    rainbow_sine: 3,
    ping_pong: 4,
    gravity: 5,
    sparkle: 6,
    show_number: 7,
    rain: 8,
    mapped_swipe: 10,
    mapped_shape: 11,
    kaleidoscope: 12,
    random_walk: 13,
    fireworks: 15,
    rotating_sectors: 16,
    fill: 17,
    rotating_plane: 18,
    twang: 19,
    flicker_sparkle: 20

  @command_type_map CommandType.__enum_map__() |> Enum.into(%{})

  @primary_key false
  embedded_schema do
    field :index, :integer
    field :type, CommandType
    field :data, {:array, :integer}, default: []
    field :enabled, :boolean, default: true

    embeds_many :modifiers, Modifier
  end

  def changeset(command, %{"type" => type} = params) when is_binary(type) do
    case Integer.parse(type) do
      {int, _} -> changeset(command, Map.put(params, "type", int))
      _ -> changeset(command, params)
    end
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:index, :type, :data, :enabled])
    |> Changeset.validate_required([:index, :type])
    |> Changeset.validate_number(:index, less_than: 256)
    |> Changeset.validate_length(:data, max: 8)
    |> Changeset.cast_embed(:modifiers)
  end

  def from_binary(<<index::size(8), type::size(8), data_bin::binary>>) do
    data = for <<element::size(8) <- data_bin>>, do: element

    %Command{}
    |> changeset(%{index: index, type: type, data: data})
    |> Ecto.Changeset.apply_action(:insert)
  end

  def from_binary(_), do: {:error, :invalid_binary_format}

  def to_binary(%Command{enabled: false, index: index}) do
    to_binary(%Command{type: :disabled, index: index})
  end

  def to_binary(%Command{index: index, type: type, data: data}) do
    type_bin = Map.fetch!(@command_type_map, type)
    data_bin = Enum.map(data, fn int -> <<int::size(8)>> end) |> Enum.join()
    <<index::size(8), type_bin::size(8), data_bin::binary>>
  end

  def defaults(index) when is_number(index) do
    defaults(%Command{type: :disabled, index: index})
  end

  def defaults(%Command{} = command) do
    data =
      Inputs.input_def(command)
      |> Enum.map(fn %{default: default} -> default end)

    %Command{command | data: data, modifiers: []}
  end

  def inputs(%Command{data: data, type: type} = command) do
    data_inputs =
      Inputs.input_def(command)
      |> case do
        :disabled ->
          []

        inputs ->
          inputs
          |> Enum.map(fn input -> Map.put(input, :variable_name, "data[]") end)
          |> Enum.with_index()
          |> Enum.map(fn {input, index} -> Map.merge(input, %{value: Enum.at(data, index, 0)}) end)
      end

    type_input = %Select{
      value: CommandType.__enum_map__()[type],
      options: types(),
      name: "Type",
      variable_name: "type",
      default: :disabled
    }

    [type_input | data_inputs]
  end

  def types() do
    Tr33Control.Commands.Command.CommandType.__enum_map__()
    |> Enum.filter(fn {type, _} -> Inputs.input_def(%Command{type: type}) |> is_list() end)
  end
end

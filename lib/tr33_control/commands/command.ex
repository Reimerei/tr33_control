defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias __MODULE__
  alias Tr33Control.Commands.Modifier
  alias Tr33Control.Commands.Inputs.{Slider, Select, Button}

  @trunk_count 8
  @branch_count 12

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
    mapped_shape: 11

  @hidden_commands [:show_number]

  @strip_index_values [
                        all: @trunk_count + @branch_count + 2,
                        all_trunks: @trunk_count + @branch_count,
                        all_branches: @trunk_count + @branch_count + 1
                      ] ++
                        Enum.map(0..(@trunk_count - 1), &{:"trunk_#{&1}", &1}) ++
                        Enum.map(0..(@branch_count - 1), &{:"branch_#{&1}", &1 + @trunk_count})

  defenum StripIndex, @strip_index_values

  defenum BallType,
    # square: 0,
    sine: 1,
    comet: 2,
    nyan: 3,
    fill_top: 4,
    fill_bottom: 5

  defenum SwipeDirection,
    top_bottom: 0,
    bottom_top: 1,
    left_right: 2,
    right_left: 3

  defenum MappedShape,
    square: 0,
    hollow_square: 1,
    circle: 2

  @primary_key false
  embedded_schema do
    field(:index, :integer)
    field(:type, CommandType)
    field(:data, {:array, :integer}, default: [])

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
    |> Changeset.cast(params, [:index, :type, :data])
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

  def to_binary(%Command{index: index, type: type, data: data}) do
    type_bin = CommandType.__enum_map__() |> Keyword.get(type)
    data_bin = Enum.map(data, fn int -> <<int::size(8)>> end) |> Enum.join()
    <<index::size(8), type_bin::size(8), data_bin::binary>>
  end

  def defaults(index) when is_number(index) do
    defaults(%Command{type: :disabled, index: index})
  end

  def defaults(%Command{} = command) do
    data =
      input_def(command)
      |> Enum.map(fn %{default: default} -> default end)

    %Command{command | data: data}
  end

  def inputs(%Command{data: data, type: type} = command) do
    data_inputs =
      input_def(command)
      |> Enum.map(fn input -> Map.put(input, :variable_name, "data[]") end)
      |> Enum.with_index()
      |> Enum.map(fn {input, index} -> Map.merge(input, %{value: Enum.at(data, index, 0)}) end)

    type_input = %Select{
      value: CommandType.__enum_map__()[type],
      enum: CommandType,
      name: "Type ",
      variable_name: "type",
      default: :disabled
    }

    [type_input | data_inputs]
  end

  def types() do
    Tr33Control.Commands.Command.CommandType.__enum_map__()
    |> Enum.map(fn {type, _} -> type end)
    |> Enum.reject(fn type -> type in @hidden_commands end)
  end

  defp input_def(%Command{type: :single_color}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 226},
      %Slider{name: "Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :rainbow_sine}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all)},
      %Slider{name: "BPM", max: 255, default: 10},
      %Slider{name: "Wavelength [pixel]", max: 255, default: 100},
      %Slider{name: "Rainbow Width [%]", max: 255, default: 100},
      %Slider{name: "Max Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :ping_pong}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all_trunks)},
      %Select{name: "Ball Type", enum: BallType, default: 1},
      %Slider{name: "Color", max: 255, default: 65},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Width", max: 255, default: 90},
      %Slider{name: "BPM", max: 255, default: 25},
      %Slider{name: "Offset", max: 100, default: 0}
    ]
  end

  defp input_def(%Command{type: :gravity}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 13},
      %Slider{name: "Initial Speed", max: 255, default: 0},
      %Slider{name: "New Balls per 10 seconds", max: 100, default: 5},
      %Slider{name: "Width", max: 255, default: 70},
      %Button{name: "Add Ball", event: :gravity}
    ]
  end

  defp input_def(%Command{type: :sparkle}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all_branches)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Sparkles per second", max: 255, default: 10}
    ]
  end

  defp input_def(%Command{type: :rain}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all_branches)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Drops per second", max: 255, default: 10},
      %Slider{name: "Rate", max: 255, default: 10}
    ]
  end

  defp input_def(%Command{type: :show_number}) do
    [
      %Select{name: "Strip Index", enum: StripIndex, default: strip_index(:all_branches)},
      %Slider{name: "Number", max: 255, default: 23}
    ]
  end

  defp input_def(%Command{type: :mapped_swipe}) do
    [
      %Select{name: "Swipe Direction", enum: SwipeDirection, default: 0},
      %Slider{name: "Color", max: 255, default: 100},
      %Slider{name: "Rate", max: 255, default: 100}
    ]
  end

  defp input_def(%Command{type: :mapped_shape}) do
    [
      %Select{name: "Shape", enum: MappedShape, default: 0},
      %Slider{name: "Color", max: 255, default: 50},
      %Slider{name: "x", max: 255, default: 100},
      %Slider{name: "y", max: 255, default: 100},
      %Slider{name: "size", max: 255, default: 50}
    ]
  end

  defp input_def(_), do: []

  def strip_index(type) do
    case StripIndex.dump(type) do
      {:ok, int} -> int
    end
  end
end

defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Command}

  defenum CommandTypes,
    disabled: 0,
    single_hue: 1,
    single_color: 2,
    color_wipe: 3,
    rainbow_sine: 4,
    ping_pong: 5,
    gravity: 6,
    off: 7,
    white: 8,
    sparkle: 9

  defenum StripIndex,
    all: 14,
    trunks_all: 12,
    branches_all: 13,
    trunk_0: 0,
    trunk_1: 1,
    trunk_2: 2,
    trunk_3: 3,
    trunk_4: 4,
    trunk_5: 5,
    branch_0: 6,
    branch_1: 7,
    branch_2: 8,
    branch_3: 9,
    branch_4: 10,
    branch_5: 11

  defenum BallType,
    # square: 0,
    sine: 1,
    comet: 2

  @primary_key false
  embedded_schema do
    field :index, :integer
    field :type, CommandTypes
    field :data, {:array, :integer}, default: []
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:index, :type, :data])
    |> Changeset.validate_required([:index, :type])
    |> Changeset.validate_number(:index, less_than: 256)
  end

  def to_binary(%Command{index: index, type: type, data: data}) do
    type_bin = CommandTypes.__enum_map__() |> Keyword.get(type)
    data_bin = Enum.map(data, fn int -> <<int::size(8)>> end) |> Enum.join()
    <<index::size(8), type_bin::size(8), data_bin::binary>>
  end

  def defaults(%Command{} = cmd) do
    data =
      properties(cmd)
      |> Enum.map(fn {_, _, value} -> value end)

    %Command{cmd | data: data}
  end

  def data_inputs(%Command{} = cmd) do
    properties(cmd)
    |> Enum.map(fn {type, properties, _} -> {type, properties} end)
  end

  def types() do
    Tr33Control.Commands.Command.CommandTypes.__enum_map__()
    |> Enum.map(fn {type, _} -> type end)
  end

  def properties(%Command{type: :single_hue}) do
    [{:select, {"Strip Index", StripIndex}, strip_index(:all)}, {:slider, {"Hue", 255}, 226}]
  end

  def properties(%Command{type: :single_color}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Hue", 255}, 0},
      {:slider, {"Saturation", 255}, 255},
      {:slider, {"Value", 255}, 255}
    ]
  end

  def properties(%Command{type: :color_wipe}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Hue", 255}, 30},
      {:slider, {"Rate", 255}, 10},
      {:slider, {"Offset", 255}, 0}
    ]
  end

  def properties(%Command{type: :rainbow_sine}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Rate [pixel/s]", 255}, 10},
      {:slider, {"Wavelength [pixel]", 255}, 100},
      {:slider, {"Rainbow Width [%]", 255}, 100},
      {:slider, {"Max Brightness", 255}, 255}
    ]
  end

  def properties(%Command{type: :ping_pong}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:trunks_all)},
      {:select, {"Ball Type", BallType}, 1},
      {:slider, {"Offset", 100}, 0},
      {:slider, {"Hue", 255}, 65},
      {:slider, {"BPM", 255}, 25},
      {:slider, {"Width", 255}, 90}
    ]
  end

  def properties(%Command{type: :gravity}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Hue", 255}, 13},
      {:slider, {"Initial Speed", 255}, 0},
      {:slider, {"New Balls per 10 seconds", 100}, 5},
      {:button, {"Add Ball"}, 0}
    ]
  end

  def properties(%Command{type: :white}) do
    [{:slider, {"Color Temperature", 255}, 255}, {:slider, {"Value", 255}, 255}]
  end

  def properties(%Command{type: :sparkle}) do
    [
      {:slider, {"Hue", 255}, 1},
      {:slider, {"Saturation", 255}, 0},
      {:slider, {"Width", 255}, 15},
      {:slider, {"Sparkles per second", 255}, 10}
    ]
  end

  def properties(_), do: []

  def strip_index(type) do
    case StripIndex.dump(type) do
      {:ok, int} -> int
      _ -> 0
    end
  end
end

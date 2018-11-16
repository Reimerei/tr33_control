defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Command}

  @trunk_count 6
  @branch_count 6

  defenum CommandType,
    disabled: 0,
    single_color: 1,
    rainbow_sine: 4,
    ping_pong: 5,
    gravity: 6,
    sparkle: 9

  @disabled_commands []

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
    fill_top: 3,
    fill_bottom: 4

  @primary_key false
  embedded_schema do
    field :index, :integer
    field :type, CommandType
    field :data, {:array, :integer}, default: []
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:index, :type, :data])
    |> Changeset.validate_required([:index, :type])
    |> Changeset.validate_number(:index, less_than: 256)
  end

  def to_binary(%Command{index: index, type: type, data: data}) do
    type_bin = CommandType.__enum_map__() |> Keyword.get(type)
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
    Tr33Control.Commands.Command.CommandType.__enum_map__()
    |> Enum.map(fn {type, _} -> type end)
    |> Enum.reject(&Enum.member?(@disabled_commands, &1))
  end

  def properties(%Command{type: :single_color}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Color", 255}, 226},
      {:slider, {"Brightness", 255}, 255}
    ]
  end

  def properties(%Command{type: :rainbow_sine}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"BPM", 255}, 10},
      {:slider, {"Wavelength [pixel]", 255}, 100},
      {:slider, {"Rainbow Width [%]", 255}, 100},
      {:slider, {"Max Brightness", 255}, 255}
    ]
  end

  def properties(%Command{type: :ping_pong}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all_trunks)},
      {:select, {"Ball Type", BallType}, 1},
      {:slider, {"Color", 255}, 65},
      {:slider, {"Brightness", 255}, 255},
      {:slider, {"Width", 255}, 90},
      {:slider, {"BPM", 255}, 25},
      {:slider, {"Offset", 100}, 0}
    ]
  end

  def properties(%Command{type: :gravity}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all)},
      {:slider, {"Color", 255}, 13},
      {:slider, {"Initial Speed", 255}, 0},
      {:slider, {"New Balls per 10 seconds", 100}, 5},
      {:button, {"Add Ball"}, 0}
    ]
  end

  def properties(%Command{type: :sparkle}) do
    [
      {:select, {"Strip Index", StripIndex}, strip_index(:all_branches)},
      {:slider, {"Color", 255}, 1},
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

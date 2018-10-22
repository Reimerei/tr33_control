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

  @background_types [:off, :single_hue, :single_color, :rainbow_sine, :white]

  defenum StripIndex,
    trunk_0: 0,
    trunk_1: 1,
    trunk_2: 2,
    trunk_3: 3,
    branch_0: 4,
    branch_1: 5,
    branch_2: 6,
    branch_3: 7,
    branch_4: 8,
    branch_5: 9,
    ring: 10

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

  def defaults(%Command{type: :single_hue} = cmd), do: %Command{cmd | data: [226]}
  def defaults(%Command{type: :single_color} = cmd), do: %Command{cmd | data: [0, 0, 255]}
  def defaults(%Command{type: :rainbow_sine} = cmd), do: %Command{cmd | data: [10, 100, 100, 255]}
  def defaults(%Command{type: :color_wipe} = cmd), do: %Command{cmd | data: [30, 10, 0]}
  def defaults(%Command{type: :ping_pong} = cmd), do: %Command{cmd | data: [4, 65, 25, 91]}
  def defaults(%Command{type: :gravity} = cmd), do: %Command{cmd | data: [10, 13, 25, 0, 50]}
  def defaults(%Command{type: :white} = cmd), do: %Command{cmd | data: [0, 255]}
  def defaults(%Command{type: :sparkle} = cmd), do: %Command{cmd | data: [1, 0, 15, 10]}
  def defaults(%Command{} = cmd), do: %Command{cmd | data: [0, 0, 0, 0, 0]}

  def types() do
    Tr33Control.Commands.Command.CommandTypes.__enum_map__()
    |> Enum.map(fn {type, _} -> type end)
    |> Enum.filter(fn type -> type not in @background_types end)
  end

  def background_types(), do: @background_types

  def data_inputs(%Command{type: :single_hue}) do
    [{:slider, {"Hue", 255}}]
  end

  def data_inputs(%Command{type: :single_color}) do
    [{:slider, {"Hue", 255}}, {:slider, {"Saturation", 255}}, {:slider, {"Value", 255}}]
  end

  def data_inputs(%Command{type: :color_wipe}) do
    [{:slider, {"Hue", 255}}, {:slider, {"Rate", 255}}, {:slider, {"Offset", 255}}]
  end

  def data_inputs(%Command{type: :rainbow_sine}) do
    [
      {:slider, {"Rate [pixel/s]", 255}},
      {:slider, {"Wavelength [pixel]", 255}},
      {:slider, {"Rainbow Width [%]", 255}},
      {:slider, {"Max Brightnes", 255}}
    ]
  end

  def data_inputs(%Command{type: :ping_pong}) do
    [
      {:select, {"Strip Index", StripIndex}},
      {:slider, {"Hue", 255}},
      {:slider, {"Rate", 255}},
      {:slider, {"Width", 255}}
    ]
  end

  def data_inputs(%Command{type: :gravity}) do
    [
      {:select, {"Strip Index", StripIndex}},
      {:slider, {"Hue", 255}},
      {:slider, {"Width", 255}},
      {:slider, {"Inital Speed", 150}},
      {:slider, {"New Balls per 10 seconds", 100}},
      {:button, {"Add Ball"}}
    ]
  end

  def data_inputs(%Command{type: :white}) do
    [{:slider, {"Color Temperature", 255}}, {:slider, {"Value", 255}}]
  end

  def data_inputs(%Command{type: :sparkle}) do
    [
      {:slider, {"Hue", 255}},
      {:slider, {"Saturation", 255}},
      {:slider, {"Width", 255}},
      {:slider, {"Sparkles per second", 255}}
    ]
  end

  def data_inputs(_), do: []
end

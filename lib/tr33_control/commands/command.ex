defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Command, HexBinary}

  defenum CommandTypes,
    disabled: 0,
    single_hue: 1,
    single_color: 2,
    color_wipe: 3,
    rainbow_sine: 4,
    ping_pong: 5,
    ping_pong_ring: 6,
    add_ball: 7

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
    branch_6: 10

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
    [{:slider, {"Rate", 255}}, {:slider, {"Wavelength", 255}}, {:slider, {"Width", 255}}]
  end

  def data_inputs(%Command{type: :ping_pong}) do
    [
      {:select, {"Strip Index", StripIndex}},
      {:slider, {"Hue", 255}},
      {:slider, {"Rate", 255}},
      {:slider, {"Width", 255}}
    ]
  end

  def data_inputs(%Command{type: :ping_pong_ring}) do
    [{:slider, {"Hue", 255}}, {:slider, {"Rate", 255}}, {:slider, {"Width", 255}}]
  end

  def data_inputs(_), do: []
end

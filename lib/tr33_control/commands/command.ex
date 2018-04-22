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
    ping_pong_ring: 6,
    add_gravity_ball: 7

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
    field :active, :boolean, default: false
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:index, :type, :data, :active])
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
  def defaults(%Command{type: :rainbow_sine} = cmd), do: %Command{cmd | data: [15, 50, 120]}
  def defaults(%Command{type: :color_wipe} = cmd), do: %Command{cmd | data: [30, 10, 0]}
  def defaults(%Command{type: :ping_pong} = cmd), do: %Command{cmd | data: [0, 65, 25, 91]}
  def defaults(%Command{type: :ping_pong_ring} = cmd), do: %Command{cmd | data: [185, 30, 45]}
  def defaults(%Command{type: :add_gravity_ball} = cmd), do: %Command{cmd | data: [0, 0, 35, 100]}
  def defaults(%Command{type: _} = cmd), do: %Command{cmd | data: [0, 0, 0, 0, 0]}

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

  def data_inputs(%Command{type: :add_gravity_ball}) do
    [
      {:select, {"Strip Index", StripIndex}},
      {:slider, {"Hue", 255}},
      {:slider, {"Width", 255}},
      {:slider, {"Inital Spped", 255}},
      {:button, {"Add Ball"}}
    ]
  end

  def data_inputs(_), do: []
end

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
    add_ball: 6

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

  def data_inputs(%Command{type: :single_hue}), do: ["Hue"]
  def data_inputs(%Command{type: :rainbow_sine}), do: ["Rate", "Wavelength", "Width"]
  def data_inputs(_), do: []
end

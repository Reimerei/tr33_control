defmodule Tr33Control.Commands.Command do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Command, HexBinary}

  defenum CommandTypes, disable: 0, single_hue: 1, single_color: 2, color_wipe: 3, rainbox_sine: 4, ping_pong: 5

  @primary_key false
  embedded_schema do
    field :index, :integer
    field :type, CommandTypes
    field :data, HexBinary
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:index, :type, :data])
    |> Changeset.validate_required([:index, :type, :data])
    |> Changeset.validate_number(:index, less_than: 256)
  end

  def to_binary(%Command{index: index, type: type, data: data}) do
    type_bin = CommandTypes.__enum_map__() |> Keyword.get(type)
    << index :: size(8), type_bin :: size(8), data :: binary-size(64) >>
  end
end

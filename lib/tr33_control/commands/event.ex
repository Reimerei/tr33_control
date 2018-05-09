defmodule Tr33Control.Commands.Event do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Event}

  defenum EventTypes, gravity: 100

  @primary_key false
  embedded_schema do
    field :type, EventTypes
  end

  def changeset(command, params) do
    command
    |> Changeset.cast(params, [:type])
    |> Changeset.validate_required([:type])
  end

  def to_binary(%Event{type: type}) do
    index = 0
    type_bin = EventTypes.__enum_map__() |> Keyword.get(type)
    data_bin = <<>>
    <<index::size(8), type_bin::size(8), data_bin::binary>>
  end
end

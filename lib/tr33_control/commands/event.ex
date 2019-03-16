defmodule Tr33Control.Commands.Event do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Event}

  defenum EventType,
    gravity: 100,
    update_settings: 101

  defenum ColorPalette,
    rainbow: 0,
    forest: 1,
    ocean: 2,
    party: 3,
    heat: 4,
    # spring_angel: 5,
    scouty: 6,
    purple_heat: 7,
    parrot: 8,
    saga: 9,
    sage2: 10

  defenum ColorTemperature,
    none: 0,
    t_1900K: 1,
    t_2600K: 2,
    t_2850K: 3,
    t_3200K: 4,
    t_5200K: 5,
    t_5400K: 6,
    t_6000K: 7,
    t_7000K: 8

  @persisted_events [:update_settings]

  @primary_key false
  embedded_schema do
    field(:type, EventType)
    field(:data, {:array, :integer}, default: [])
  end

  def changeset(event, params) do
    event
    |> Changeset.cast(params, [:type, :data])
    |> Changeset.validate_required([:type])
  end

  def to_binary(%Event{type: type, data: data}) do
    index = 0
    type_bin = EventType.__enum_map__() |> Keyword.get(type)
    data_bin = Enum.map(data, fn int -> <<int::size(8)>> end) |> Enum.join()
    <<index::size(8), type_bin::size(8), data_bin::binary>>
  end

  def persist?(%Event{type: type}), do: type in @persisted_events

  def types() do
    Tr33Control.Commands.Event.EventType.__enum_map__()
    |> Enum.map(fn {type, _} -> type end)
  end

  def defaults(%Event{} = event) do
    data =
      properties(event)
      |> Enum.map(fn {_, _, default} -> default end)

    %Event{event | data: data}
  end

  def data_inputs(%Event{} = event) do
    properties(event)
    |> Enum.map(fn {type, properties, _} -> {type, properties} end)
  end

  def properties(%Event{type: :update_settings}) do
    [
      {:select, {"Color Palette", ColorPalette}, 0},
      {:select, {"Color Temperature", ColorTemperature}, 0}
    ]
  end

  def properties(_), do: []
end

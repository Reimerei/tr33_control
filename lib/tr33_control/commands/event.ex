defmodule Tr33Control.Commands.Event do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Event, Inputs}

  defenum EventType,
    gravity: 100,
    update_settings: 101,
    # beat: 102,
    pixel: 103,
    pixel_rgb: 104

  # game:    2

  @persisted_events [:update_settings]

  @primary_key false
  embedded_schema do
    field :type, EventType
    field :data, {:array, :integer}, default: []
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

  def from_binary(<<index::size(8), type::size(8), data_bin::binary>>) do
    data = for <<element::size(8) <- data_bin>>, do: element

    %Event{}
    |> changeset(%{index: index, type: type, data: data})
    |> Ecto.Changeset.apply_action(:insert)
  end

  def from_binary(_), do: {:error, :invalid_binary_format}

  def persist?(%Event{type: type}), do: type in @persisted_events

  def types() do
    Tr33Control.Commands.Event.EventType.__enum_map__()
    |> Enum.filter(fn {type, _} -> Inputs.input_def(%Event{type: type}) |> is_list() end)
  end

  def defaults(%Event{} = event) do
    data =
      Inputs.input_def(event)
      |> Enum.map(fn %{default: default} -> default end)

    %Event{event | data: data}
  end

  def inputs(%Event{data: data} = event) do
    Inputs.input_def(event)
    |> Enum.map(fn input -> Map.put(input, :variable_name, "data[]") end)
    |> Enum.with_index()
    |> Enum.map(fn {input, index} -> Map.merge(input, %{value: Enum.at(data, index, 0)}) end)
  end
end

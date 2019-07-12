defmodule Tr33Control.Commands.Event do
  use Ecto.Schema
  import EctoEnum
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Event}
  alias Tr33Control.Commands.Command.StripIndex
  alias Tr33Control.Commands.Inputs.{Select, Slider}

  defenum EventType,
    gravity: 100,
    update_settings: 101,
    # beat: 102,
    pixel: 103,
    pixel_rgb: 104

  defenum ColorPalette,
    rainbow: 0,
    forest: 1,
    ocean: 2,
    party: 3,
    heat: 4,
    spring_angel: 5,
    scouty: 6,
    purple_heat: 7,
    # parrot: 8,
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

  defenum DisplayMode,
    commands: 0,
    stream: 1

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
    |> Enum.map(fn {type, _} -> type end)
  end

  def defaults(%Event{} = event) do
    data =
      input_def(event)
      |> Enum.map(fn %{default: default} -> default end)

    %Event{event | data: data}
  end

  def inputs(%Event{data: data} = event) do
    input_def(event)
    |> Enum.map(fn input -> Map.put(input, :variable_name, "data[]") end)
    |> Enum.with_index()
    |> Enum.map(fn {input, index} -> Map.merge(input, %{value: Enum.at(data, index, 0)}) end)
  end

  defp input_def(%Event{type: :update_settings}) do
    [
      %Select{name: "Color Palette", options: ColorPalette.__enum_map__(), default: 0},
      %Select{name: "Color Temperature", options: ColorTemperature.__enum_map__(), default: 0},
      %Select{name: "Display Mode", options: DisplayMode.__enum_map__(), default: 0}
    ]
  end

  defp input_def(%Event{type: :pixel}) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Color", max: 255, default: 13}
    ]
  end

  defp input_def(%Event{type: :pixel_rgb}) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Red", max: 255, default: 13},
      %Slider{name: "Green", max: 255, default: 13},
      %Slider{name: "Blue", max: 255, default: 13}
    ]
  end

  # defp input_dev(%Event{type: :pixel}) do
  #   [
  #     %
  #   ]
  # end

  defp input_def(_), do: []
end

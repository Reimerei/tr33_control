defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema
  import EctoEnum

  alias Ecto.Changeset
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Inputs.{Select, Slider, Hidden}

  defenum ModifierType,
    disabled: 0,
    linear: 1,
    sine: 2,
    quadratic: 3,
    # cubic: 4,
    sawtooth: 5,
    sawtooth_reverse: 6,
    random: 7,
    random_transitions: 8

  @primary_key false
  @enforce_keys [:index, :data_index]
  embedded_schema do
    field :type, ModifierType, default: :disabled
    field :index, :integer
    field :data_index, :integer
    field :data_length, :integer, default: 1
    field :beats_per_minute, :integer, default: 0
    field :offset, :integer, default: 0
    field :max, :integer, default: 255
    field :min, :integer, default: 0
  end

  def changeset(modifier, %{"type" => type} = params) when is_binary(type) do
    case Integer.parse(type) do
      {int, _} -> changeset(modifier, Map.put(params, "type", int))
      _ -> changeset(modifier, params)
    end
  end

  def changeset(modifier, params) do
    modifier
    |> Changeset.cast(params, __MODULE__.__schema__(:fields))
  end

  def new(index, data_index) do
    params =
      input_def(command_max(index, data_index))
      |> Enum.map(fn {key, %{default: default}} -> {key, default} end)
      |> Enum.reject(&match?({_, nil}, &1))
      |> Enum.into(%{})
      |> Map.put(:max, command_max(index, data_index))

    %__MODULE__{
      index: index,
      data_index: data_index
    }
    |> changeset(params)
    |> Changeset.apply_action(:insert)
  end

  def inputs(%__MODULE__{index: index, data_index: data_index} = modifier) do
    inputs =
      command_max(index, data_index)
      |> input_def()
      |> Enum.map(fn {key, input} ->
        input
        |> Map.put(:value, Map.fetch!(modifier, key))
        |> Map.put(:variable_name, Atom.to_string(key))
        |> Map.put(:index, index)
      end)

    {inputs, command_name(index, data_index), data_index}
  end

  def to_binary(%__MODULE__{} = modifier) do
    type_bin =
      ModifierType.__enum_map__()
      |> Enum.into(%{})
      |> Map.fetch!(modifier.type)

    <<
      type_bin::size(8),
      modifier.index::size(8),
      modifier.data_index::size(8),
      modifier.data_length::size(8),
      modifier.beats_per_minute::size(16),
      modifier.offset::size(16),
      modifier.max::size(8),
      modifier.min::size(8)
    >>
  end

  def display_offset(val) when is_number(val), do: val / 10

  def display_beats_per_minute(val) when is_number(val),
    do: "#{floor(val / 256)}." <> String.pad_leading("#{round(rem(val, 256) * 1000 / 256)}", 3, "0")

  defp input_def(command_max) do
    [
      type: %Select{name: "Modifier Type", options: ModifierType.__enum_map__(), default: 0},
      beats_per_minute: %Slider{
        name: "Cycles per Minute",
        max: 256 * 256 - 1,
        default: 512,
        display_fun: &display_beats_per_minute/1
      },
      offset: %Slider{name: "Offset [s]", max: 256 * 256 - 1, default: 0, display_fun: &display_offset/1},
      min: %Slider{name: "Min value", max: command_max, default: 0},
      max: %Slider{name: "Max value", max: command_max, default: command_max},
      data_index: %Hidden{}
    ]
  end

  # there are better ways to do this
  defp command_max(index, data_index) do
    Commands.get_command(index)
    |> Commands.inputs([])
    |> Enum.find(&match?(%{data_index: ^data_index}, &1))
    |> input_max()
  end

  defp input_max(%Slider{max: max}), do: max
  defp input_max(%Select{options: options}), do: Enum.max_by(options, fn {_key, value} -> value end) |> elem(1)
  defp input_max(_), do: 0

  defp command_name(index, data_index) do
    Commands.get_command(index)
    |> Commands.inputs([])
    |> Enum.find(&match?(%{data_index: ^data_index}, &1))
    |> input_name()
  end

  defp input_name(%Slider{name: name}), do: name
  defp input_name(%Select{name: name}), do: name
  defp input_name(_), do: "THIS SHOULD NOT BE HERE"
end

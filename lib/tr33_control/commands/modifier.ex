defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema
  import EctoEnum

  alias Ecto.Changeset
  alias Tr33Control.Commands.Command
  alias Tr33Control.Commands.Inputs.{Select, Slider, Hidden}

  # todo
  # handle enums
  # fix flickering controls on update
  # missing modifier types

  defenum ModifierType,
    linear: 0,
    sine: 1,
    sawtooth: 2

  # random: 3

  @primary_key false
  embedded_schema do
    field :field_index, :integer
    field :field_name, :string
    field :type, ModifierType
    field :period, :integer
    field :offset, :integer
    field :max, :integer
    field :min, :integer
  end

  def new() do
    %__MODULE__{}
    |> defaults()
  end

  def changeset(command, %{"type" => type} = params) when is_binary(type) do
    case Integer.parse(type) do
      {int, _} -> changeset(command, Map.put(params, "type", int))
      _ -> changeset(command, params)
    end
  end

  def changeset(modifier, params) do
    modifier
    |> Changeset.cast(params, [:field_index, :field_name, :type, :period, :offset, :max, :min])
  end

  def apply(%__MODULE__{period: 0}, %Command{} = command), do: command

  def apply(%__MODULE__{min: min, max: max, field_index: field_index} = modifier, %Command{data: data} = command) do
    fraction = fraction(modifier)
    value = (min + (max - min) * fraction) |> round
    %Command{command | data: List.replace_at(data, field_index, value)}
  end

  def defaults(%__MODULE__{} = modifier) do
    defaults =
      input_def()
      |> Enum.map(fn {key, %{default: default}} -> {key, default} end)
      |> Enum.into(%{})

    Map.merge(modifier, defaults)
  end

  def inputs(%__MODULE__{field_name: field_name} = modifier) do
    inputs =
      input_def()
      |> Enum.map(fn {key, input} ->
        input
        |> Map.put(:value, Map.fetch!(modifier, key))
        |> Map.put(:variable_name, Atom.to_string(key))
      end)

    {inputs, field_name}
  end

  def for_command(%Command{} = command) do
    Command.inputs(command)
    |> Enum.reject(&match?(%{name: "Type"}, &1))
    |> Enum.with_index()
    |> Enum.filter(&match?({%Slider{}, _}, &1))
    |> Enum.map(fn {%Slider{name: name}, index} ->
      %__MODULE__{}
      |> defaults
      |> Map.put(:field_index, index)
      |> Map.put(:field_name, name)
    end)
  end

  defp input_def() do
    [
      field_index: %Hidden{},
      field_name: %Hidden{},
      type: %Select{name: "Type", options: ModifierType.__enum_map__(), default: :linear},
      period: %Slider{name: "Period [s]", max: 600, default: 0},
      offset: %Slider{name: "Offset [s]", max: 600, default: 0},
      min: %Slider{name: "Min value", max: 255, default: 0},
      max: %Slider{name: "Max value", max: 255, default: 255}
    ]
  end

  defp fraction(%__MODULE__{period: 0}), do: 0

  defp fraction(%__MODULE__{type: :linear, period: period, offset: offset}) do
    period = period * 1000
    offset = offset * 1000

    case rem(System.os_time(:millisecond) + offset, period) do
      rem when rem <= period / 2 -> rem / (period / 2)
      rem -> 1 - (rem - period / 2) / (period / 2)
    end
  end

  defp fraction(%__MODULE__{type: :sine, period: period, offset: offset}) do
    (:math.sin((System.os_time(:millisecond) - offset * 1000) * 2 * :math.pi() / period * 1000) + 1) / 2
  end

  defp fraction(%__MODULE__{type: :sawtooth, period: period, offset: offset}) do
    period = period * 1000
    offset = offset * 1000

    rem(System.os_time(:millisecond) + offset, period) / period
  end
end

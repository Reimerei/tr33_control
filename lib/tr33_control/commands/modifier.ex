defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema
  import EctoEnum

  alias Ecto.Changeset
  alias Tr33Control.Commands.Command
  alias Tr33Control.Commands.Inputs.{Select, Slider, Button}

  # todo
  # add delete button for modifier
  # enable/disable switch for modifiers (maybe)
  # handle enums
  # rate limit
  # fix flickering controls on update

  defenum ModifierType,
    linear: 0,
    sine: 1,
    sawtooth: 2,
    random: 3

  @primary_key false
  embedded_schema do
    field :field, :integer
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
    |> Changeset.cast(params, [:field, :type, :period, :offset, :max, :min])
  end

  def apply(%__MODULE__{min: min, max: max, field: field} = modifier, %Command{data: data} = command) do
    fraction = fraction(modifier)
    value = (min + (max - min) * fraction) |> round
    %Command{command | data: List.replace_at(data, field, value)}
  end

  def defaults(%__MODULE__{} = modifier) do
    defaults =
      input_def(%Command{})
      |> Enum.map(fn {key, %{default: default}} -> {key, default} end)
      |> Enum.into(%{})

    Map.merge(modifier, defaults)
  end

  def inputs(%Command{modifiers: modifiers} = command) do
    modifiers
    |> Enum.with_index()
    |> Enum.map(fn {modifier, index} ->
      inputs =
        input_def(command)
        |> Enum.map(fn {key, input} ->
          input
          |> Map.put(:value, Map.fetch!(modifier, key))
          |> Map.put(:variable_name, Atom.to_string(key))
        end)

      inputs ++ [%Button{name: "delete", event: "modifier_delete", data: index}]
    end)
  end

  defp input_def(%Command{} = command) do
    field_options =
      Command.inputs(command)
      |> Enum.reject(&match?(%{name: "Type"}, &1))
      |> Enum.with_index()
      |> Enum.map(fn {%{name: name}, index} -> {name, index} end)

    [
      field: %Select{name: "Modified Field", options: field_options, default: 0},
      type: %Select{name: "Modifier Type", options: ModifierType.__enum_map__(), default: :sine},
      period: %Slider{name: "Period [s]", max: 60000, step: 500, default: 5000},
      offset: %Slider{name: "Offset [s]", max: 60000, step: 500, default: 0},
      min: %Slider{name: "Min value", max: 255, default: 0},
      max: %Slider{name: "Max value", max: 255, default: 255}
    ]
  end

  defp fraction(%__MODULE__{period: 0}), do: 0

  defp fraction(%__MODULE__{type: :linear, period: period, offset: offset}) do
    case rem(System.os_time(:millisecond) + offset, period) do
      rem when rem <= period / 2 -> rem / (period / 2)
      rem -> 1 - (rem - period / 2) / (period / 2)
    end
  end

  defp fraction(%__MODULE__{type: :sine, period: period, offset: offset}) do
    (:math.sin((System.os_time(:millisecond) - offset) * 2 * :math.pi() / period) + 1) / 2
  end

  # defp fraction(%__MODULE__{type: :cos, period: period} = modifier) do
  #   :math.cos(passed_time(modifier) * 2 * :math.pi() / (period * 2))
  # end

  # defp passed_time(%__MODULE__{period: period, offset: offset}) do
  #   rem(, period)
  # end
end

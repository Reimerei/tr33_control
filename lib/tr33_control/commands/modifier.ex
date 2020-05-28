defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema
  import EctoEnum

  alias Ecto.Changeset
  alias Tr33Control.Commands.Command
  alias Tr33Control.Commands.Inputs.{Select, Slider, Hidden}

  defenum ModifierType,
    linear: 0,
    sine: 1,
    sawtooth: 2,
    random: 3,
    random_transitions: 4

  @primary_key false
  embedded_schema do
    field :field_index, :integer
    field :type, ModifierType
    field :period, :integer
    field :offset, :integer
    field :max, :integer
    field :min, :integer
  end

  def changeset(command, %{"type" => type} = params) when is_binary(type) do
    case Integer.parse(type) do
      {int, _} -> changeset(command, Map.put(params, "type", int))
      _ -> changeset(command, params)
    end
  end

  def changeset(modifier, params) do
    modifier
    |> Changeset.cast(params, [:field_index, :type, :period, :offset, :max, :min])
  end

  def apply(%__MODULE__{period: 0}, %Command{} = command), do: command

  def apply(%__MODULE__{min: min, max: max, field_index: field_index} = modifier, %Command{data: data} = command) do
    fraction = fraction(modifier)
    value = (min + (max - min) * fraction) |> round
    %Command{command | data: List.replace_at(data, field_index, value)}
  end

  def inputs_for_command(%Command{modifiers: modifiers} = command) do
    command_inputs = data_inputs(command)

    for %__MODULE__{field_index: index} = modifier <- modifiers do
      command_input = Enum.at(command_inputs, index)
      {inputs(modifier, input_max(command_input)), input_name(command_input)}
    end
  end

  def defaults_for_command(%Command{} = command) do
    command
    |> data_inputs
    |> Enum.with_index()
    |> Enum.filter(&supported_input?/1)
    |> Enum.map(fn {input, index} ->
      %__MODULE__{}
      |> defaults(input_max(input))
      |> Map.put(:field_index, index)
    end)
  end

  defp inputs(%__MODULE__{} = modifier, max) do
    input_def(max)
    |> Enum.map(fn {key, input} ->
      input
      |> Map.put(:value, Map.fetch!(modifier, key))
      |> Map.put(:variable_name, Atom.to_string(key))
    end)
  end

  defp defaults(%__MODULE__{} = modifier, max) do
    defaults =
      input_def(max)
      |> Enum.map(fn {key, %{default: default}} -> {key, default} end)
      |> Enum.into(%{})

    Map.merge(modifier, defaults)
  end

  defp input_def(max) do
    [
      field_index: %Hidden{},
      type: %Select{name: "Type", options: ModifierType.__enum_map__(), default: 0},
      period: %Slider{name: "Period [s]", max: 600, default: 0},
      offset: %Slider{name: "Offset [s]", max: 600, default: 0},
      min: %Slider{name: "Min value", max: max, default: 0},
      max: %Slider{name: "Max value", max: max, default: max}
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
    period = period * 1000
    offset = offset * 1000

    (:math.sin((System.os_time(:millisecond) - offset) * 2 * :math.pi() / period) + 1) / 2
  end

  defp fraction(%__MODULE__{type: :sawtooth, period: period, offset: offset}) do
    period = period * 1000
    offset = offset * 1000

    rem(System.os_time(:millisecond) + offset, period) / period
  end

  defp fraction(%__MODULE__{type: :random, period: period, offset: offset}) do
    key_value = period
    period = period * 1000
    offset = offset * 1000

    last_update_map = Application.get_env(:tr33_control, :modifier_random_last_update, %{})
    last_value_map = Application.get_env(:tr33_control, :modifier_random_last_value, %{})
    last_period = div(Map.get(last_update_map, key_value, 0) + offset, period)

    now = System.os_time(:millisecond)
    current_period = div(now + offset, period)

    if current_period > last_period do
      value = :random.uniform()
      Application.put_env(:tr33_control, :modifier_random_last_value, Map.put(last_value_map, key_value, value))
      Application.put_env(:tr33_control, :modifier_random_last_update, Map.put(last_update_map, key_value, now))
      value
    else
      Map.get(last_value_map, key_value, 0)
    end
  end

  defp fraction(%__MODULE__{type: :random_transitions, period: period, offset: offset} = modifier) do
    key = :erlang.phash2(modifier)
    period = period * 1000
    offset = offset * 1000

    state = Application.get_env(:tr33_control, :"modifier_random_transition_#{key}", %{})
    last_update = Map.get(state, :last_update, 0)
    current_value = Map.get(state, :current_value, 0)
    next_value = Map.get(state, :next_value, 0)

    now = System.os_time(:millisecond)
    current_period = div(now + offset, period)
    last_period = div(Map.get(state, :last_update, 0) + offset, period)

    {current_value, next_value, last_update} =
      if current_period > last_period do
        {next_value, :random.uniform(), now}
      else
        {current_value, next_value, last_update}
      end

    state =
      state
      |> Map.put(:last_update, last_update)
      |> Map.put(:current_value, current_value)
      |> Map.put(:next_value, next_value)

    Application.put_env(:tr33_control, :"modifier_random_transition_#{key}", state)
    ease(current_value, next_value, now - last_update, period)
  end

  defp ease(current, next, time_elapsed, period) do
    Ease.ease_in_out_cubic(time_elapsed, current, next - current, period)
  end

  defp data_inputs(%Command{} = command) do
    Command.inputs(command)
    |> Enum.filter(&supported_input?/1)
    |> Enum.filter(&(input_variable_name(&1) == "data[]"))
  end

  defp supported_input?(%Slider{}), do: true
  defp supported_input?(%Select{}), do: true
  defp supported_input?({%Slider{}, _}), do: true
  defp supported_input?({%Select{}, _}), do: true
  defp supported_input?(_), do: false

  defp input_name(%Slider{name: name}), do: name
  defp input_name(%Select{name: name}), do: name

  defp input_variable_name(%Slider{variable_name: name}), do: name
  defp input_variable_name(%Select{variable_name: name}), do: name

  defp input_max(%Slider{max: max}), do: max
  defp input_max(%Select{options: options}), do: Enum.max_by(options, fn {_key, value} -> value end) |> elem(1)
end

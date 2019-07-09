defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema

  alias Ecto.Changeset
  alias Tr33Control.Commands.Inputs.{Select, Slider}

  embedded_schema do
    field :period, :integer
    field :offset, :integer
  end

  def new() do
    %__MODULE__{}
    |> defaults()
  end

  def changeset(modifier, params) do
    modifier
    |> Changeset.cast(params, [:period, :offset])
  end

  def defaults(%__MODULE__{} = modifier) do
    defaults =
      input_def()
      |> Enum.map(fn {key, %{default: default}} -> {key, default} end)
      |> Enum.into(%{})

    Map.merge(modifier, defaults)
  end

  def inputs(%__MODULE__{} = modifier) do
    input_def()
    |> Enum.map(fn {key, input} ->
      input
      |> Map.put(:value, Map.fetch!(modifier, key))
      |> Map.put(:variable_name, Atom.to_string(key))
    end)
  end

  defp input_def() do
    %{
      period: %Slider{name: "Period", max: 10000, default: 3000},
      offset: %Slider{name: "Offset", max: 10000, default: 0}
    }
  end
end

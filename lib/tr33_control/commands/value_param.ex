defmodule Tr33Control.Commands.ValueParam do
  alias Tr33Control.Commands.Command
  alias Tr33Control.Commands.ProtoBuf.CommonParams

  @enforce_keys [:name]
  defstruct [:value, :name, min: 0, max: 255, step: 1]

  def get_common(%Command{params: %{common: %CommonParams{} = common}}, name) do
    %__MODULE__{
      name: name,
      value: Map.fetch!(common, name)
    }
  end

  def list(%Command{params: params} = command) do
    Command.list_params(command)
    |> Enum.filter(&match?(%{type: :int32}, &1))
    |> Enum.map(fn %{name: name} ->
      %__MODULE__{
        name: name,
        value: Map.fetch!(params, name)
      }
    end)
  end

  # defp overrides(type, field), do: %{}
end

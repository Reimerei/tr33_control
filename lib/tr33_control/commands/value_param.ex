defmodule Tr33Control.Commands.ValueParam do
  alias Protobuf.Field

  @enforce_keys [:name]
  defstruct [:value, :name, min: 0, max: 255, step: 1]

  def new(struct, %Field{type: :int32} = field_def) when is_struct(struct) do
    %__MODULE__{
      name: field_def.name,
      value: Map.fetch!(struct, field_def.name)
    }
  end

  def new(_, _), do: nil

  # def get_common(%Command{params: %{common: %CommonParams{} = common}}, name) do
  #   %__MODULE__{
  #     name: name,
  #     value: Map.fetch!(common, name)
  #   }
  # end

  # def list(%Command{params: params} = command) do
  #   Command.list_params(command)
  #   |> Enum.filter(&match?(%{type: :int32}, &1))
  #   |> Enum.map(fn %{name: name} ->
  #     %__MODULE__{
  #       name: name,
  #       value: Map.fetch!(params, name)
  #     }
  #   end)
  # end

  # defp overrides(value_paramstruct, name), do: %{}
end

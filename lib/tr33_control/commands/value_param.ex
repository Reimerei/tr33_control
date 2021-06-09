defmodule Tr33Control.Commands.ValueParam do
  alias Protobuf.Field
  alias Tr33Control.Commands.Schemas

  @enforce_keys [:name]
  defstruct [:value, :name, min: 0, max: 255, step: 1]

  def new(struct, %Field{type: :int32} = field_def) when is_struct(struct) do
    %__MODULE__{
      name: field_def.name,
      value: Map.fetch!(struct, field_def.name)
    }
    |> override(struct)
  end

  def new(_, _), do: nil

  defp override(%__MODULE__{name: :position} = param, %Schemas.Render{}) do
    %__MODULE__{param | max: 256 * 256, step: 64}
  end

  defp override(%__MODULE__{} = param, _), do: param
end

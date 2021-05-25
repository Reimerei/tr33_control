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
end

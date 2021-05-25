defmodule Tr33Control.Commands.EnumParam do
  alias Protobuf.Field

  @enforce_keys [:name, :options]
  defstruct [:value, :name, :options]

  def new(struct, %Field{type: {:enum, type}} = field_def) when is_struct(struct) do
    %__MODULE__{
      name: field_def.name,
      value: Map.fetch!(struct, field_def.name),
      options: apply(type, :atoms, [])
    }
  end

  def new(_, _), do: nil
end

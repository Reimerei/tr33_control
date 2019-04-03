defmodule Tr33Control.Commands.Inputs.Button do
  @enforce_keys [:name, :event]
  defstruct [:name, :event, default: 0]
end

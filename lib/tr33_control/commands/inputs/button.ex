defmodule Tr33Control.Commands.Inputs.Button do
  @enforce_keys [:name, :event]
  defstruct [:index, :name, :event, data: 0, default: 0, has_modifier?: false]
end

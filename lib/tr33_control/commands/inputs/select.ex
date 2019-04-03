defmodule Tr33Control.Commands.Inputs.Select do
  @enforce_keys [:name, :enum, :default]
  defstruct [:name, :enum, :default, :value]
end

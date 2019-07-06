defmodule Tr33Control.Commands.Inputs.Select do
  @enforce_keys [:name, :enum, :default]
  defstruct [:name, :variable_name, :enum, :default, :value]
end

defmodule Tr33Control.Commands.Inputs.Select do
  @enforce_keys [:name, :options, :default]
  defstruct [:name, :variable_name, :options, :default, :value]
end

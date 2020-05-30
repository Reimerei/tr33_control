defmodule Tr33Control.Commands.Inputs.Slider do
  @enforce_keys [:name, :max, :default]
  defstruct [:name, :variable_name, :max, :default, :value, :modifier, step: 1]
end

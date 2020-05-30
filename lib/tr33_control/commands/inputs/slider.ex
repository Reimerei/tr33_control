defmodule Tr33Control.Commands.Inputs.Slider do
  @enforce_keys [:name, :max, :default]
  defstruct [:index, :name, :variable_name, :max, :default, :value, step: 1, has_modifier?: false]
end

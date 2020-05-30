defmodule Tr33Control.Commands.Inputs.Hidden do
  @enforce_keys []
  defstruct [:index, :variable_name, :value, default: 0, has_modifier?: false]
end

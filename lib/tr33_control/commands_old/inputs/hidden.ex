defmodule Tr33Control.Commands.Inputs.Hidden do
  @enforce_keys []
  defstruct [:data_index, :variable_name, :value, :default, has_modifier?: false]
end

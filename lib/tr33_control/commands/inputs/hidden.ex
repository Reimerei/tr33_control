defmodule Tr33Control.Commands.Inputs.Hidden do
  @enforce_keys []
  defstruct [:variable_name, :value, default: 0]
end

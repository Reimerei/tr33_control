defmodule Tr33Control.Commands.Inputs.Slider do
  @enforce_keys [:name, :max, :default]
  defstruct [:name, :max, :default, :value]
end

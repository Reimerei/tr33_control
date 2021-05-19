defmodule Tr33Control.Commands.Inputs.Select do
  @enforce_keys [:name, :options, :default]
  defstruct [
    :data_index,
    :name,
    :variable_name,
    :options,
    :default,
    :value,
    has_modifier?: false,
    data_length: 1
  ]
end

defmodule Tr33Control.Commands.Inputs.Slider do
  @enforce_keys [:name, :max, :default]
  defstruct [
    :data_index,
    :name,
    :variable_name,
    :max,
    :default,
    :value,
    step: 1,
    has_modifier?: false,
    display_fun: &__MODULE__.default_display_fun/1,
    data_length: 1
  ]

  def default_display_fun(val), do: val
end

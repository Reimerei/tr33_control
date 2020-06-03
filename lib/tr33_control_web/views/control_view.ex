defmodule Tr33ControlWeb.ControlView do
  use Tr33ControlWeb, :view

  alias Tr33Control.Commands.Preset
  alias Tr33Control.Commands.Inputs.{Select, Slider, Button}

  def format(int) when is_integer(int) and int < 1000 do
    to_string(int)
  end

  def format(int) when is_integer(int) do
    "#{round(int / 1000)}.#{rem(int, 1000)}"
  end

  def preset_name_with_default(%Preset{default: true, name: name}), do: "#{name} [default]"
  def preset_name_with_default(%Preset{name: name}), do: name
end

defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view

  alias Tr33Control.Commands.Inputs.{Select, Slider, Button}

  def format(int) when is_integer(int) and int < 1000 do
    to_string(int)
  end

  def format(int) when is_integer(int) do
    "#{round(int / 1000)}.#{rem(int, 1000)}"
  end
end

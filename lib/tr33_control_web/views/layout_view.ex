defmodule Tr33ControlWeb.LayoutView do
  use Tr33ControlWeb, :view

  def title do
    "#{Tr33Control.Commands.LedStructure.display_name()} Control"
  end
end

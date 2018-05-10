defmodule Tr33ControlWeb.LayoutView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands.Preset

  def name(%Preset{name: name}), do: name
  def name(_), do: nil
end

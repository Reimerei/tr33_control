defmodule Tr33ControlWeb.LayoutView do
  use Tr33ControlWeb, :view

  def title do
    case Application.fetch_env!(:tr33_control, :led_structure) do
      :tr33 -> "Tr33 Control"
      :dode -> "Dode Control"
      :keller -> "Keller Control"
    end
  end
end

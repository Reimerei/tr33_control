defmodule Tr33ControlWeb.InputComponent do
  use Tr33ControlWeb, :live_component
  require Logger

  alias Tr33Control.Commands.Inputs.{Select, Slider, Button, Hidden}
end

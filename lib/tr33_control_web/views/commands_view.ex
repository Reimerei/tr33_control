defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands.Command

  def data_inputs(%Command{} = command) do
    Command.data_inputs(command)
    |> Enum.with_index()
  end
end

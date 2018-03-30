defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands.Command

  def data_inputs(%Command{} = command) do
    Command.data_inputs(command)
    |> Enum.with_index()
  end

  def slider_id(%Command{index: index}, data_index) do
    "slider_#{index}_#{data_index}"
  end

  def data_value(%Command{data: data}, data_index) do
    Enum.at(data, data_index, 0)
  end
end

defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command}

  def data_inputs(struct) do
    Commands.data_inputs(struct)
    |> Enum.with_index()
  end

  def data_value(%{data: data}, data_index) do
    Enum.at(data, data_index, 0)
  end

  def seleted_name(%{current_preset: name}) when is_binary(name), do: name
  def seleted_name(_), do: ""

  def types(%Command{index: _}), do: Command.types()

  def type_label(%Command{index: _}), do: "Effect"
end

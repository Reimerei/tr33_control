defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands.{Command, Cache}

  def data_inputs(%Command{} = command) do
    Command.data_inputs(command)
    |> Enum.with_index()
  end

  def data_value(%Command{data: data}, data_index) do
    Enum.at(data, data_index, 0)
  end

  def commands() do
    Cache.get_all()
  end

  def current_name(%{current_name: name}) when is_binary(name), do: name
  def current_name(_), do: ""

  def types(%Command{index: 0}), do: Command.background_types() |> IO.inspect()
  def types(%Command{index: _}), do: Command.types()

  def type_label(%Command{index: 0}), do: "Background"
  def type_label(%Command{index: _}), do: "Effect"
end

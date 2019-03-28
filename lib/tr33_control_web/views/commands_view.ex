defmodule Tr33ControlWeb.CommandsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event}

  def data_inputs(struct) do
    Commands.data_inputs(struct)
    |> Enum.with_index()
    |> Enum.map(fn {input, index} -> {input, input_assigns(struct, index)} end)
  end

  def input_assigns(%{data: data}, index) do
    %{data_index: index, data_value: Enum.at(data, index, 0)}
  end

  def seleted_name(%{current_preset: name}) when is_binary(name), do: name
  def seleted_name(_), do: ""

  def types(%Command{index: _}), do: Command.types()

  def type_label(%Command{index: _}), do: "Effect"

  def index(%{index: index}), do: index
  def index(_), do: 0

  def type(%{type: type}), do: type

  def action(%Command{}), do: "command"
  def action(%Event{}), do: "event"

  def render_type_select(%Command{}), do: true
  def render_type_select(_), do: false
end

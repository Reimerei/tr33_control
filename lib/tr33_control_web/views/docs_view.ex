defmodule Tr33ControlWeb.DocsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event}

  @rejected_data_input_types [:button]

  def type_number(%Command{type: type}) do
    Command.CommandType.__enum_map__() |> Keyword.get(type)
  end

  def type_number(%Event{type: type}) do
    Event.EventType.__enum_map__() |> Keyword.get(type)
  end

  def type_text(%{type: type}) do
    type
  end

  def data_texts(command_or_event) do
    Commands.data_inputs(command_or_event)
    |> Enum.reject(fn {type, _} -> type in @rejected_data_input_types end)
    |> Enum.map(fn {_, {name, _}} -> name end)
  end

  def enum_name(enum) do
    Module.split(enum)
    |> Enum.reverse()
    |> hd
  end

  def enum_values(enum) do
    enum.__enum_map__()
    |> Enum.to_list()
  end
end

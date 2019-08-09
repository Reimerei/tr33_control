defmodule Tr33ControlWeb.DocsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event}
  alias Tr33Control.Commands.Inputs.{Button, Select, Slider}

  @excluded_inputs [Button]

  def type_number(%Command{type: type}) do
    Command.CommandType.__enum_map__()
    |> Keyword.get(type)
    |> to_string()
  end

  def type_number(%Event{type: type}) do
    Event.EventType.__enum_map__()
    |> Keyword.get(type)
    |> to_string()
  end

  def type_text(%{type: type} = action) do
    "#{type_number(action)} (#{type})"
  end

  def data_texts(command_or_event) do
    Commands.inputs(command_or_event)
    |> Enum.reject(&(&1.variable_name == "type"))
    |> Enum.reject(fn %{__struct__: struct} -> struct in @excluded_inputs end)
    |> Enum.map(&data_text/1)
  end

  def data_text(%Select{name: name}) do
    "#{name}"
  end

  def data_text(%Slider{name: name}) do
    "#{name}"
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

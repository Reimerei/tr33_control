defmodule Tr33ControlWeb.DocsView do
  use Tr33ControlWeb, :view
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @rejected_data_input_types [:button]

  def type_number(%Command{type: type}) do
    Command.CommandType.__enum_map__() |> Keyword.get(type)
  end

  def type_text(%Command{type: type}) do
    type
  end

  def data_texts(%Command{} = command) do
    Commands.data_inputs(command)
    |> Enum.reject(fn {type, _} -> type in @rejected_data_input_types end)
    |> Enum.map(fn {_, {name, _}} -> name end)
  end
end

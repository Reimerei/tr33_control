defmodule Tr33Control.Commands.CommandList do
  @behaviour Ecto.Type

  alias Tr33Control.Commands

  def type, do: :string

  def cast(list) when is_list(list) do
    {:ok, list}
  end

  def load(string) do
    case Poison.decode(string) do
      {:ok, list} -> {:ok, Enum.map(list, &Commands.new_command!/1)}
      error -> error
    end
  end

  def dump(list) when is_list(list) do
    list
    |> Enum.map(&Map.take(&1, Commands.Command.__schema__(:fields)))
    |> Poison.encode()
  end
end

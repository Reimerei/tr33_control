defmodule Tr33Control.Commands.Cache do
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  @ets_table :commands
  @max_index Application.fetch_env!(:tr33_control, :command_max_index)

  def init() do
    :ets.new(@ets_table, [:named_table, :public])

    0..@max_index
    |> Enum.map(&default/1)
    |> Enum.map(&Commands.create_command!/1)
    |> Enum.map(&Commands.Command.defaults/1)
    |> Enum.map(&Commands.Cache.insert/1)
    |> Enum.map(&Commands.Socket.send/1)
  end

  def insert(%Command{index: index} = command) do
    true = :ets.insert(@ets_table, {index, command})
    command
  end

  def get(index) do
    case :ets.lookup(@ets_table, index) do
      [{^index, command = %Command{}}] ->
        command

      [] ->
        nil
    end
  end

  def get_all() do
    for index <- 0..@max_index do
      get(index)
    end
  end

  defp default(0 = index), do: %{index: index, type: :rainbow_sine}
  defp default(index), do: %{index: index, type: :disabled}
end

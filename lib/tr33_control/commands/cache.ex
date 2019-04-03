defmodule Tr33Control.Commands.Cache do
  require Logger
  alias Tr33Control.Commands.{Command, Event}

  @commands_ets :commands
  @events_ets :events

  def init() do
    :ets.new(@commands_ets, [:named_table, :public])
    :ets.new(@events_ets, [:named_table, :public])

    0..Application.fetch_env!(:tr33_control, :command_max_index)
    |> Enum.map(&Command.defaults/1)
    |> Enum.map(&insert/1)

    [
      %Event{type: :update_settings}
    ]
    |> Enum.map(&Event.defaults/1)
    |> Enum.map(&insert/1)
  end

  def clear() do
    :ets.delete_all_objects(@commands_ets)
  end

  def insert(%Command{index: index} = command) do
    :ets.insert(@commands_ets, {index, command})
    command
  end

  def insert(%Event{type: type} = event) do
    :ets.insert(@events_ets, {type, event})
    event
  end

  def all() do
    all_commands() ++ all_events()
  end

  def get_command(index) do
    case :ets.lookup(@commands_ets, index) do
      [{^index, command = %Command{}}] -> command
      [] -> nil
    end
  end

  def all_commands() do
    :ets.match_object(@commands_ets, {:_, :_})
    |> Enum.sort_by(fn {index, _} -> index end)
    |> Enum.map(fn {_, event} -> event end)
  end

  def delete_command(index) do
    :ets.delete(@commands_ets, index)
  end

  def get_event(type) do
    case :ets.lookup(@events_ets, type) do
      [{^type, event = %Event{}}] -> event
      [] -> nil
    end
  end

  def all_events() do
    :ets.match_object(@events_ets, {:_, :_})
    |> Enum.map(fn {_, event} -> event end)
  end
end

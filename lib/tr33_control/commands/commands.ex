defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket, Event}

  @cache_persist_file [:code.priv_dir(:tr33_control), "cache.bin"] |> Path.join()

  def create_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_command(%Command{} = command) do
    command
    |> Command.to_binary()
    |> Socket.send()
  end

  def create_event!(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_event(%Event{} = event) do
    event
    |> Event.to_binary()
    |> Socket.send()
  end

  def cache_init() do
    cache =
      try do
        File.read!(@cache_persist_file)
        |> :erlang.binary_to_term()
      rescue
        _ ->
          cache_default()
      end

    Application.put_env(:tr33_control, :commands, cache)
  end

  def cache_default() do
    [
      %Command{index: 0, type: :disabled},
      %Command{index: 1, type: :disabled},
      %Command{index: 2, type: :disabled},
      %Command{index: 3, type: :disabled},
      %Command{index: 4, type: :disabled},
      %Command{index: 5, type: :disabled},
      %Command{index: 6, type: :disabled}
    ]
  end

  def cache_get(index) do
    Application.fetch_env!(:tr33_control, :commands)
    |> Enum.at(index)
  end

  def cache_persist() do
    binary =
      Application.fetch_env!(:tr33_control, :commands)
      |> :erlang.term_to_binary()

    File.write!(@cache_persist_file, binary)
  end

  def cache_put(%Command{index: index} = new_command) do
    cache = Application.fetch_env!(:tr33_control, :commands)
    new_cache = List.replace_at(cache, index, new_command)
    Application.put_env(:tr33_control, :commands, new_cache)
    new_command
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error),
    do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

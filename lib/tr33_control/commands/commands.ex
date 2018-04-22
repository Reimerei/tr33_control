defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket}

  @cache_persist_file [:code.priv_dir(:tr33_control), "cache.bin"] |> Path.join()

  def create_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
    |> cache_update()
  end

  def send_command(%Command{type: :add_gravity_ball, active: false}), do: :noop

  def send_command(%Command{} = command) do
    command
    |> Socket.send_command()
    |> IO.inspect(label: :send_command)
  end

  def cache_init() do
    cache =
      if File.exists?(@cache_persist_file) do
        File.read!(@cache_persist_file)
        |> :erlang.binary_to_term()
      else
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

    Application.put_env(:tr33_control, :commands, cache)
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

  defp cache_update(%Command{index: index} = new_command) do
    cache = Application.fetch_env!(:tr33_control, :commands)

    old_command = Enum.at(cache, new_command.index)
    new_cache = List.replace_at(cache, index, new_command)

    Application.put_env(:tr33_control, :commands, new_cache)

    {new_command, old_command}
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error),
    do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

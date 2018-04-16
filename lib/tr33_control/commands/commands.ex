defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket}

  def create_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
    |> cache_update()
  end

  def send_command(%Command{type: :add_ball, active: false}), do: :noop

  def send_command(%Command{} = command) do
    command
    |> Socket.send_command()
    |> IO.inspect(label: :send_command)
  end

  def cache_init() do
    cache = [
      %Command{index: 0, type: :single_hue, data: [50]},
      %Command{index: 1, type: :disabled},
      %Command{index: 2, type: :disabled},
      %Command{index: 3, type: :disabled},
      %Command{index: 4, type: :disabled}
    ]

    Application.put_env(:tr33_control, :commands, cache)
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

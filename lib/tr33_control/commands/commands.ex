defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket}

  def create_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error
  end

  def send_command(%Command{} = command) do
    command
    |> Socket.send_command()
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error),
    do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket, Event, Cache, Preset}

  def create_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_command(%Command{} = command) do
    command
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

  def create_preset!(params) do
    commands = Cache.get_all()

    %Preset{}
    |> Preset.changeset(params, commands)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

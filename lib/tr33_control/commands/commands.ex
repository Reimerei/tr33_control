defmodule Tr33Control.Commands do
  alias Tr33Control.Repo
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

  def create_preset(params) do
    commands = Cache.get_all()

    with {:ok, name} <- Map.fetch(params, "name"),
         preset when not is_nil(preset) <- Repo.get_by(Preset, name: name) do
      preset
    else
      _ -> %Preset{}
    end
    |> Preset.changeset(params, commands)
    |> Repo.insert_or_update()
  end

  def list_presets() do
    Repo.all(Preset)
  end

  def get_preset(name) when not is_nil(name) do
    Repo.get_by(Preset, name: name)
  end

  def get_preset(_), do: nil

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

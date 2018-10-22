defmodule Tr33Control.Commands do
  import Ecto.Query, only: [from: 2]
  alias Tr33Control.Repo
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset}

  def init() do
    Cache.init()

    case latest_preset() do
      %Preset{name: name} -> load_preset(name)
      nil -> :noop
    end
  end

  def new_command!(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_command(%Command{} = command) do
    command
    |> Cache.insert()
    |> UART.send()
  end

  def list_commands() do
    Cache.get_all()
  end

  def get_command(index) do
    Cache.get(index)
  end

  def new_event!(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_event(%Event{} = event) do
    event
    |> UART.send()
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
    query = from p in Preset, order_by: [asc: p.name]

    Repo.all(query)
  end

  def load_preset(name) when not is_nil(name) do
    preset = Repo.get_by!(Preset, name: name)

    %Preset{commands: commands} = preset
    Enum.each(commands, &Cache.insert/1)
    UART.resync()

    preset
  end

  def latest_preset() do
    query = from p in Preset, order_by: [desc: p.updated_at], limit: 1
    Repo.one(query)
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

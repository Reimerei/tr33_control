defmodule Tr33Control.Commands do
  import Ecto.Query, only: [from: 2]
  import EctoEnum
  alias Tr33Control.Repo
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset, ColorPalette}

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
    Cache.all_commands()
  end

  def get_command(index) do
    Cache.get_command(index)
  end

  def new_event(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def new_event!(params) do
    new_event(params)
    |> raise_on_error()
  end

  def send_event(%Event{} = event) do
    event
    |> UART.send()
  end

  def create_preset(params) do
    commands = list_commands()

    with {:ok, name} <- Map.fetch(params, "name"),
         preset when not is_nil(preset) <- Repo.get_by(Preset, name: name) do
      preset
    else
      _ -> %Preset{}
    end
    |> Preset.changeset(params, commands)
    |> Repo.insert_or_update()

    Application.put_env(:tr33_control, :current_preset, name)
  end

  def list_presets() do
    query = from p in Preset, order_by: [asc: p.name]

    Repo.all(query)
  end

  def load_preset(%Preset{commands: commands, name: name} = preset) do
    Application.put_env(:tr33_control, :current_preset, name)
    Enum.map(commands, &Cache.insert/1)
    UART.resync()

    preset
  end

  def load_preset(name) when is_binary(name) and not is_nil(name) do
    Repo.get_by!(Preset, name: name)
    |> load_preset()
  end

  def latest_preset() do
    query = from p in Preset, order_by: [desc: p.updated_at], limit: 1
    Repo.one(query)
  end

  def current_preset() do
    Application.get_env(:tr33_control, :current_preset, "")
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

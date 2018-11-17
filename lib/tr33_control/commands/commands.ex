defmodule Tr33Control.Commands do
  import Ecto.Query, only: [from: 2]
  import EctoEnum
  alias Tr33Control.Repo
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset, ColorPalette}

  defenum ColorPalette,
    rainbow: 0,
    forest: 1,
    ocean: 2,
    party: 3,
    heat: 4,
    purple_fly: 5,
    spring_angel: 6,
    scoutie: 7

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

  def new_event!(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> raise_on_error()
  end

  def send_event(%Event{} = event) do
    event
    |> maybe_insert()
    |> UART.send()
  end

  def list_events() do
    Cache.all_events()
  end

  def create_preset(params) do
    commands = list_commands()
    events = list_events()

    with {:ok, name} <- Map.fetch(params, "name"),
         preset when not is_nil(preset) <- Repo.get_by(Preset, name: name) do
      preset
    else
      _ -> %Preset{}
    end
    |> Preset.changeset(params, commands, events)
    |> Repo.insert_or_update()
  end

  def list_presets() do
    query = from p in Preset, order_by: [asc: p.name]

    Repo.all(query)
  end

  def load_preset(%Preset{commands: commands, events: events, name: name} = preset) do
    Application.put_env(:tr33_control, :current_preset, name)
    Enum.map(commands, &Cache.insert/1) |> IO.inspect()
    Enum.map(events, &Cache.insert/1)
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

  defp maybe_insert(%Event{} = event) do
    if Event.persist?(event) do
      Cache.insert(event)
    end

    event
  end
end

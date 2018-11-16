defmodule Tr33Control.Commands do
  import Ecto.Query, only: [from: 2]
  import EctoEnum
  alias Tr33Control.Repo
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset, ColorPalette}

  defenum ColorPalette,
    rainbow: 0,
    cloud: 1,
    forest: 2,
    lava: 3,
    ocean: 4,
    party: 5,
    heat: 6

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
    color_palette = get_color_palette()

    with {:ok, name} <- Map.fetch(params, "name"),
         preset when not is_nil(preset) <- Repo.get_by(Preset, name: name) do
      preset
    else
      _ -> %Preset{}
    end
    |> Preset.changeset(params, commands, color_palette)
    |> Repo.insert_or_update()
  end

  def list_presets() do
    query = from p in Preset, order_by: [asc: p.name]

    Repo.all(query)
  end

  def load_preset(%Preset{commands: commands, color_palette: color_palette} = preset) do
    Enum.each(commands, &Cache.insert/1)
    set_color_palette(color_palette)
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

  def list_color_palettes() do
    Tr33Control.Commands.ColorPalette.__enum_map__()
  end

  def get_color_palette() do
    Application.fetch_env!(:tr33_control, :color_palette)
  end

  def set_color_palette(color_palette) when is_integer(color_palette) do
    Application.put_env(:tr33_control, :color_palette, color_palette)
  end

  def set_color_palette(color_palette) when is_atom(color_palette) do
    index = ColorPalette.__enum_map__() |> Keyword.fetch!(color_palette)
    Application.put_env(:tr33_control, :color_palette, index)
  end

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")
end

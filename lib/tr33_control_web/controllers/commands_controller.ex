defmodule Tr33ControlWeb.CommandsController do
  use Tr33ControlWeb, :controller
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Preset}

  def index(conn, _params) do
    preset_names = get_presets(conn) |> Map.keys()
    current_preset = fetch_flash(conn, :current_preset)

    conn
    |> render("index.html", preset_names: preset_names, current_preset: current_preset)
  end

  def create_preset(%Plug.Conn{body_params: params} = conn, _params) do
    preset = %Preset{name: name} = Commands.create_preset!(params)
    presets = get_presets(conn) |> Map.put(name, preset)

    conn
    |> put_session(:presets, presets)
    |> put_flash(:current_preset, name)
    |> redirect(to: commands_path(conn, :index))
  end

  def load_preset(conn, %{"name" => name}) do
    presets = get_presets(conn)

    case Map.fetch(presets, name) do
      {:ok, %Preset{commands: commands}} ->
        commands
        |> Enum.filter(&command_valid?/1)
        |> Enum.map(&Commands.Cache.insert/1)
        |> Enum.map(&Commands.Socket.send/1)

        Tr33ControlWeb.CommandsChannel.update_all()

      other ->
        Logger.error("could not find preset #{inspect(name)}, result@ #{inspect(other)}")
    end

    conn
    |> redirect(to: commands_path(conn, :index))
  end

  defp get_presets(conn) do
    case get_session(conn, :presets) do
      presets when is_map(presets) -> presets
      _ -> %{}
    end
  end

  defp command_valid?(%Command{} = command) do
    %Ecto.Changeset{valid?: valid?} = Command.changeset(command, %{})
    valid?
  end
end

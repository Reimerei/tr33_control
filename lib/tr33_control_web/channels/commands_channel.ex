defmodule Tr33ControlWeb.CommandsChannel do
  use Phoenix.Channel
  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Cache, Preset}

  def join("live_forms", msg, socket) do
    Logger.debug("Join in commands channel, msg: #{inspect(msg)}")
    command_forms = Cache.get_all() |> Enum.map(&render_form/1)
    presets_form = Commands.list_presets() |> render_form()

    {:ok, %{msgs: [presets_form | command_forms]}, socket}
  end

  def handle_in("form_change", %{"form_type" => "command"} = msg, socket) do
    msg
    |> normalize_data()
    |> Commands.create_command!()
    |> broadcast_form(socket)
    |> Commands.Cache.insert()
    |> Commands.send_command()

    {:noreply, socket}
  end

  def handle_in("form_change", %{"form_type" => "presets"} = msg, socket) do
    assigns =
      case Map.get(msg, "load_preset") |> Commands.get_preset() do
        nil ->
          %{message: "Error loading preset"}

        %Preset{commands: commands, name: name} ->
          commands
          |> Enum.map(&Commands.Cache.insert/1)
          |> Enum.map(fn command -> broadcast!(socket, "form", render_form(command)) end)

          %{message: "Loaded preset #{name}", current_name: name}
      end

    presets_form = Commands.list_presets() |> render_form(assigns)
    broadcast(socket, "form", presets_form)
    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "command"} = msg, socket) do
    msg
    |> Commands.create_event!()
    |> Commands.send_event()

    {:noreply, socket}
  end

  def handle_in("button", %{"form_type" => "presets"} = msg, socket) do
    result =
      case Commands.create_preset(msg) do
        {:ok, %Preset{name: name}} -> "Saved #{inspect(name)}"
        {:error, _} -> "Error saving #{inspect(Map.get(msg, "name"))}"
      end

    presets_form =
      Commands.list_presets()
      |> render_form(%{message: result, current_name: Map.get(msg, "name")})

    broadcast(socket, "form", presets_form)

    {:noreply, socket}
  end

  def update_all() do
    Cache.get_all()
    |> Enum.map(&render_form/1)
    |> Enum.each(&Tr33ControlWeb.Endpoint.broadcast!("live_forms", "form", &1))
  end

  defp broadcast_form(%Command{index: index, type: type} = command, socket) do
    %Command{type: prev_type} = Commands.Cache.get(index)

    if type != prev_type do
      command = Command.defaults(command)
      broadcast!(socket, "form", render_form(command))
      command
    else
      broadcast_from!(socket, "form", render_form(command))
      command
    end
  end

  defp render_form(struct, assigns \\ %{})

  defp render_form(%Command{} = command, _) do
    html = Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_command.html", command: command)

    %{id: "#{command.index}", html: html}
  end

  defp render_form(presets, assigns) when is_list(presets) do
    html =
      Phoenix.View.render_to_string(Tr33ControlWeb.CommandsView, "_presets.html", Map.put(assigns, :presets, presets))

    %{id: "presets", html: html}
  end

  defp normalize_data(msg) do
    msg
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.reduce(%{"data" => []}, fn {key, value}, acc ->
      case key do
        "data_" <> _ ->
          Map.update!(acc, "data", fn data -> [value | data] end)

        _ ->
          Map.put(acc, key, value)
      end
    end)
  end
end

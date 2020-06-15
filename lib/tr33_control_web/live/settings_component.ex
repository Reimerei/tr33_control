defmodule Tr33ControlWeb.SettingsComponent do
  use Tr33ControlWeb, :live_component

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Preset}

  def update(_parent_assigns, socket) do
    settings_inputs =
      Commands.get_event(:update_settings)
      |> Commands.inputs()

    presets =
      Commands.list_presets()
      |> Enum.sort_by(fn %Preset{name: name} -> name end)

    socket =
      socket
      |> assign(:presets, presets)
      |> assign(:settings_inputs, settings_inputs)
      |> current_preset_changeset

    {:ok, socket}
  end

  def handle_event("preset_load", %{"name" => name}, socket) do
    Logger.debug("preset_load: #{inspect(name)}")
    %Preset{name: name} = Commands.load_preset(name)

    socket =
      socket
      |> put_flash(:info, "Preset #{inspect(name)} loaded")
      |> current_preset_changeset()

    {:noreply, socket}
  end

  def handle_event("preset_save", %{"preset" => params}, socket) do
    socket =
      case Commands.create_preset(params) do
        {:ok, %Preset{name: name}} ->
          socket
          |> put_flash(:info, "Preset #{inspect(name)} saved")
          |> current_preset_changeset()

        {:error, changeset} ->
          Logger.error("Error creating preset' #{inspect(changeset)}")

          socket
          |> put_flash(:info, "Error writing preset")
          |> assign(:preset_changeset, changeset)
      end

    {:noreply, socket}
  end

  def handle_event("preset_validate", %{"preset" => params}, socket) do
    changeset =
      %Preset{}
      |> Commands.change_preset(params)
      |> Map.put(:action, :insert)

    socket =
      socket
      |> assign(:preset_changeset, changeset)

    {:noreply, socket}
  end

  def handle_event("preset_delete", %{"name" => name}, socket) do
    flash =
      case Commands.delete_preset(name) do
        {:ok, _} -> "Preset #{inspect(name)} deleted"
        _ -> "Could not delete Preset #{inspect(name)}"
      end

    socket =
      socket
      |> put_flash(:info, flash)
      |> current_preset_changeset()

    {:noreply, socket}
  end

  def handle_event("preset_set_default", %{"name" => name}, socket) do
    flash =
      case Commands.set_default_preset(name) do
        %Preset{name: name} -> "Set preset #{inspect(name)} as default"
        nil -> ""
      end

    socket =
      socket
      |> put_flash(:info, flash)

    {:noreply, socket}
  end

  def handle_event("settings_change", params, socket) do
    Logger.debug("settings_change: #{inspect(params)}")

    params
    |> Map.put("type", "update_settings")
    |> Commands.new_event!()
    |> Commands.send_to_esp()

    {:noreply, socket}
  end

  def handle_event(event, data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    {:noreply, socket}
  end

  defp current_preset_changeset(socket) do
    socket
    |> assign(:preset_changeset, Commands.get_current_preset() |> Commands.change_preset())
  end

  defp preset_name_with_default(%Preset{default: true, name: name}), do: "#{name} [default]"
  defp preset_name_with_default(%Preset{name: name}), do: name
end

defmodule Tr33ControlWeb.CommandComponent do
  use Tr33ControlWeb, :live_component
  require Logger
  alias Phoenix.LiveView.Socket
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command

  def update(%{id: id} = assigns, socket) do
    command = Commands.get_command(id)
    command_inputs = Commands.inputs(command)

    socket =
      Enum.reduce(0..9, socket, fn index, socket_acc ->
        assign(socket_acc, String.to_atom("input_#{index}"), Enum.at(command_inputs, index))
      end)
      |> assign(:command, command)
      |> assign(:id, id)
      |> assign(:command_types, Commands.command_types())
      |> assign(:collapsed?, Map.get(assigns, :collaped?, command.type == :disabled))
      |> assign(:modifier_inputs, Commands.modifier_inputs(command))

    {:ok, socket}
  end

  def handle_event("type_change", %{"new_type" => new_type}, %Socket{assigns: %{id: id}} = socket) do
    %{index: id, type: new_type}
    |> Commands.new_command!()
    |> Command.defaults()
    |> Commands.send(true)

    {:noreply, socket}
  end

  def handle_event("data_change", params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.edit_command!(params)
    |> Commands.send(true)

    {:noreply, socket}
  end

  def handle_event("command_up", _params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.swap_commands(id - 1)

    {:noreply, socket}
  end

  def handle_event("command_down", _params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.swap_commands(id + 1)

    {:noreply, socket}
  end

  def handle_event("command_clone", _params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.clone_command(id + 1)

    {:noreply, socket}
  end

  def handle_event("command_toggle_enabled", _params, %Socket{assigns: %{id: id}} = socket) do
    %Command{enabled: enabled} = command = Commands.get_command(id)

    command
    |> Commands.edit_command!(%{enabled: !enabled})
    |> Commands.send()

    {:noreply, socket}
  end

  def handle_event("command_toggle_collapsed", _params, %Socket{assigns: assigns} = socket) do
    {:noreply, assign(socket, :collapsed?, not Map.get(assigns, :collapsed?, false))}
  end

  def handle_event("modifier_create", %{"index" => index}, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.create_modifier(String.to_integer(index))

    {:noreply, socket}
  end

  def handle_event("modifier_delete", %{"index" => index}, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.delete_modifier(String.to_integer(index))

    {:noreply, socket}
  end

  def handle_event("modifier_change", %{"index" => index} = params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.update_modifier!(String.to_integer(index), params)

    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Params: #{inspect(params)}")
    {:noreply, socket}
  end
end

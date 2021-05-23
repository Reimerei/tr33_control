defmodule Tr33ControlWeb.CommandComponent do
  use Tr33ControlWeb, :live_component
  require Logger
  alias Phoenix.LiveView.Socket
  alias Tr33Control.Commands
  alias Tr33Control.Commands.Command
  alias Tr33ControlWeb.Display

  @command_targets Application.compile_env!(:tr33_control, :command_targets)

  def mount(socket) do
    socket =
      socket
      |> assign(command_types: Commands.command_types())
      |> assign(command_targets: @command_targets)

    {:ok, socket}
  end

  # index update, current command is already at that index. Do nothing
  def update(%{index: index}, %Socket{assigns: %{command: %Command{index: index}}} = socket) do
    {:ok, socket}
  end

  # index update, current command is differnt or does there is none at all. Fetch it
  def update(%{index: index}, %Socket{} = socket) do
    command = Commands.get_command(index)
    {:ok, update_command(socket, command)}
  end

  # command update, its index matches the active one. Update
  def update(%{command: %Command{index: i} = command}, %Socket{assigns: %{command: %Command{index: i}}} = socket) do
    {:ok, update_command(socket, command)}
  end

  # command update, but its index does not match the active one. Ignore
  def update(%{command: _}, socket) do
    {:ok, socket}
  end

  def handle_event("type_select", %{"type" => type_str}, %Socket{assigns: %{command: %Command{index: index}}} = socket) do
    type = String.to_existing_atom(type_str)
    Commands.create_command(index, type)

    {:noreply, socket}
  end

  def handle_event(
        "toggle_target",
        %{"target" => target_str},
        %Socket{assigns: %{command: %Command{index: index}}} = socket
      ) do
    target = String.to_existing_atom(target_str)
    Commands.toggle_command_target(index, target)

    {:noreply, socket}
  end

  def handle_event(event, data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    {:noreply, socket}
  end

  def handle_info(data, socket) do
    Logger.warn("#{__MODULE__}: Unhandled info #{inspect(data)}")
    {:noreply, socket}
  end

  defp update_command(socket, command) do
    socket
    |> assign(command: command)
    |> assign(value_params: Commands.list_value_params(command))
    |> assign(value_params: Commands.list_enum_params(command))
  end
end

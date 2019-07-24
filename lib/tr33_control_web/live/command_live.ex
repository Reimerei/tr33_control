defmodule Tr33ControlWeb.CommandLive do
  use Phoenix.LiveView

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command}
  alias Phoenix.LiveView.Socket

  def render(assigns) do
    Tr33ControlWeb.CommandsView.render("_command.html", assigns)
  end

  def mount(%{index: index}, socket) do
    if connected?(socket), do: Commands.subscribe()

    socket =
      socket
      |> assign(:index, index)
      |> fetch()

    {:ok, socket}
  end

  def handle_event("command_change", params, %Socket{assigns: %{index: index}} = socket) do
    Logger.debug("command_change: #{inspect(params)}")

    new_command =
      Commands.get_command(index)
      |> Commands.edit_command!(Map.put(params, "index", index))

    %Command{type: new_type} = new_command
    %Command{type: old_type} = Commands.get_command(index)

    if new_type != old_type do
      new_command
      |> Command.defaults()
    else
      new_command
    end
    |> Commands.send()

    reply(socket)
  end

  def handle_event("command_up", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.swap_commands(index - 1)

    reply(socket)
  end

  def handle_event("command_down", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.swap_commands(index + 1)

    reply(socket)
  end

  def handle_event("command_clone", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.clone_command(index + 1)

    reply(socket)
  end

  def handle_event("command_reset", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.Command.defaults(index)
    |> Commands.send()

    reply(socket)
  end

  def handle_event("enable_modifiers", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.enable_modifiers()

    reply(socket)
  end

  def handle_event("disable_modifiers", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.disable_modifiers()

    reply(socket)
  end

  def handle_event("modifier_change", params, %Socket{assigns: %{index: index}} = socket) do
    modifier_index =
      Map.fetch!(params, "index")
      |> String.to_integer()

    Commands.get_command(index)
    |> Commands.update_modifier!(modifier_index, params)

    reply(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("CommandLive: Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  def handle_info({:command_update, index}, %Socket{assigns: %{index: index}} = socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info({:preset_load, _}, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info(_data, socket) do
    # Logger.debug("CommandLive: Unhandled info #{inspect(data)}")
    reply(socket)
  end

  defp fetch(%Socket{assigns: %{index: index}} = socket) do
    command = Commands.get_command(index)
    command_inputs = Commands.inputs(command)

    Enum.reduce(0..9, socket, fn index, socket_acc ->
      assign(socket_acc, String.to_atom("input_#{index}"), Enum.at(command_inputs, index))
    end)
    |> assign(:modifier_inputs, Commands.modifier_inputs(command))
  end

  defp reply(socket), do: {:noreply, socket}
end

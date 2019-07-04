defmodule Tr33ControlWeb.CommandLive do
  use Phoenix.LiveView

  require Logger

  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command}
  alias Tr33Control.Commands.Inputs.{Slider, Select, Button}
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
    new_command = Commands.new_command!(params)

    %Command{type: new_type} = new_command
    %Command{type: old_type} = Commands.get_command(index)

    if new_type != old_type do
      new_command
      |> Command.defaults()
    else
      new_command
    end
    |> Commands.send()

    Commands.notify_subscribers(:command_update)

    reply(socket)
  end

  def handle_event("command_up", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.swap_commands(index - 1)

    Commands.notify_subscribers(:command_update)

    reply(socket)
  end

  def handle_event("command_down", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.swap_commands(index + 1)

    Commands.notify_subscribers(:command_update)

    reply(socket)
  end

  def handle_event("command_clone", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.get_command(index)
    |> Commands.clone_command(index + 1)

    Commands.notify_subscribers(:command_update)

    reply(socket)
  end

  def handle_event("command_reset", _params, %Socket{assigns: %{index: index}} = socket) do
    Commands.Command.defaults(index)
    |> Commands.send()

    Commands.notify_subscribers(:command_update)

    reply(socket)
  end

  def handle_event(event, data, socket) do
    Logger.warn("Unhandled event #{inspect(event)} Data: #{inspect(data)}")
    reply(socket)
  end

  def handle_info(:command_update, socket) do
    socket
    |> fetch
    |> reply
  end

  def handle_info(_, socket), do: reply(socket)

  defp fetch(%Socket{assigns: %{index: index}} = socket) do
    command = %Command{type: type} = Commands.get_command(index)
    inputs = Commands.inputs(command)

    selects = for %Select{} = input <- inputs, do: input
    sliders = for %Slider{} = input <- inputs, do: input
    buttons = for %Button{} = input <- inputs, do: input

    type_select = %Select{
      value: Command.CommandType.__enum_map__()[type],
      enum: Command.CommandType,
      name: "Effect",
      default: :disabled
    }

    socket
    |> assign(:selects, selects)
    |> assign(:sliders, sliders)
    |> assign(:buttons, buttons)
    |> assign(:type_select, type_select)
  end

  defp reply(socket), do: {:noreply, socket}
end

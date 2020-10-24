defmodule Tr33ControlWeb.CommandComponent do
  use Tr33ControlWeb, :live_component
  require Logger
  alias Phoenix.LiveView.Socket
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Modifier}

  def mount(socket) do
    socket =
      socket
      |> assign(:collapsed?, true)

    {:ok, socket}
  end

  def update(update_assigns, %Socket{assigns: assigns} = socket) do
    %{id: id} = Map.merge(assigns, update_assigns)
    command = Commands.get_command(id)
    command_inputs = Commands.inputs(command)

    socket =
      Enum.reduce(0..9, socket, fn index, socket_acc ->
        assign(socket_acc, String.to_atom("input_#{index}"), Enum.at(command_inputs, index))
      end)
      |> assign(:id, id)
      |> assign(:command_types, Commands.command_types())
      |> assign(:command, command)
      |> assign(:modifier_inputs, Commands.modifier_inputs(command))
      |> maybe_set_collapsed?(command, Map.get(assigns, :command))

    {:ok, socket}
  end

  def handle_event("type_change", %{"type" => new_type}, %Socket{assigns: %{id: id}} = socket) do
    %{index: id, type: String.to_integer(new_type)}
    |> Commands.new_command!()
    |> Command.defaults()
    |> Commands.send_to_esp(true)

    socket
    |> set_default_collapsed?(new_type)

    {:noreply, socket}
  end

  def handle_event("data_change", params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> Commands.edit_command!(params)
    |> Commands.send_to_esp(true)

    {:noreply, socket}
  end

  def handle_event("data_increase", %{"index" => index}, %Socket{assigns: %{id: id}} = socket) do
    command = %Command{data: data} = Commands.get_command(id)

    command
    |> Commands.edit_command!(%{data: List.update_at(data, String.to_integer(index), &increment_data/1)})
    |> Commands.send_to_esp(true)

    {:noreply, socket}
  end

  def handle_event("data_decrease", %{"index" => index}, %Socket{assigns: %{id: id}} = socket) do
    command = %Command{data: data} = Commands.get_command(id)

    command
    |> Commands.edit_command!(%{data: List.update_at(data, String.to_integer(index), &decrement_data/1)})
    |> Commands.send_to_esp(true)

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
    |> Commands.send_to_esp()

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

  def handle_event("modifier_increase", params, %Socket{assigns: %{id: id}} = socket) do
    %{"index" => index, "variable_name" => variable_name} = params
    index = String.to_integer(index)
    variable_name = String.to_existing_atom(variable_name)

    command = %Command{modifiers: %{^index => modifier}} = Commands.get_command(id)
    Commands.update_modifier!(command, index, %{variable_name => increment_modifier_value(modifier, variable_name)})
    {:noreply, socket}
  end

  def handle_event("modifier_decrease", params, %Socket{assigns: %{id: id}} = socket) do
    %{"index" => index, "variable_name" => variable_name} = params
    index = String.to_integer(index)
    variable_name = String.to_existing_atom(variable_name)

    command = %Command{modifiers: %{^index => modifier}} = Commands.get_command(id)
    Commands.update_modifier!(command, index, %{variable_name => decrement_modifier_value(modifier, variable_name)})
    {:noreply, socket}
  end

  def handle_event("toggle_target", _params, %Socket{assigns: %{id: id}} = socket) do
    Commands.get_command(id)
    |> next_target()
    |> Commands.send_to_esp()

    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("#{__MODULE__}: Unhandled event #{inspect(event)} Params: #{inspect(params)}")
    {:noreply, socket}
  end

  def increment_data(data) when data < 255, do: data + 1
  def increment_data(data), do: data

  def decrement_data(data) when data > 0, do: data + -1
  def decrement_data(data), do: data

  def increment_modifier_value(%Modifier{} = modifier, variable_name) do
    case Map.fetch!(modifier, variable_name) do
      number when is_number(number) -> number + 1
      other -> other
    end
  end

  def decrement_modifier_value(%Modifier{} = modifier, variable_name) do
    case Map.fetch!(modifier, variable_name) do
      number when is_number(number) and number > 0 -> number + -1
      other -> other
    end
  end

  def maybe_set_collapsed?(socket, %Command{type: type}, %Command{type: type}), do: socket

  def maybe_set_collapsed?(socket, %Command{type: new_type}, _) do
    set_default_collapsed?(socket, new_type)
  end

  def set_default_collapsed?(socket, new_type) do
    assign(socket, :collapsed?, new_type == :disabled || new_type == "disabled")
  end

  defp next_target(%Command{target: "all"} = command), do: %Command{command | target: "udp"}
  defp next_target(%Command{target: "udp"} = command), do: %Command{command | target: "uart"}
  defp next_target(%Command{target: "uart"} = command), do: %Command{command | target: "all"}
end

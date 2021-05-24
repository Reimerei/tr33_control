defmodule Tr33ControlWeb.SelectComponent do
  use Tr33ControlWeb, :live_component
  alias Tr33Control.Commands.EnumParam
  alias Tr33ControlWeb.Display

  def update(%{target: target, param: %EnumParam{} = param} = assigns, socket) do
    socket =
      socket
      |> assign(target: target)
      |> assign(value: param.value)
      |> assign(options: param.options)
      |> assign(name: param.name)
      |> assign(style: Map.get(assigns, :style))

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="btn-group">
      <button type="button" class="btn btn-<%= label_class(@style) %> text-start"><%= Display.humanize_str(@name) %></button>

      <div class="btn-group">
        <button type="button" class="btn btn-primary text-start dropdown-toggle" data-bs-toggle="dropdown"><%= Display.humanize_str(@value) %></button>
        <div class="dropdown-menu">
          <%= for option <- @options do %>
            <div
              class="dropdown-item"
              style="cursor: pointer"
              phx-click="select_change"
              phx-value-name="<%= @name %>"
              phx-value-selected="<%= option %>"
              phx-target="<%= @target %>"
              >
              <%= Display.humanize_str(option) %>
            </div>
          <% end %>
        </div>
      </div>
    </div>

    """
  end

  defp label_class(:header), do: "secondary"
  defp label_class(_), do: "dark"
end

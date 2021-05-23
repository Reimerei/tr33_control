defmodule Tr33ControlWeb.SelectComponent do
  use Tr33ControlWeb, :live_component

  def render(%{min: _, max: _, step: _, value: _, name: _, target: _} = assigns) do
    ~L"""
      <form phx-change="slider_change" phx-auto-recover="ignore" phx-target="<%= @target %>" >
        <input
          type="range"
          class="form-range custom-vertical-range"
          mix=<%= @min %>
          max=<%= @max %>
          value=<%= @value %>
          step=<%= @step %>
          name="<%= @name %>">
      </form>
    """
  end
end

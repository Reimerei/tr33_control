defmodule Tr33ControlWeb.Display do
  alias Tr33Control.Commands.{Command, ValueParam}

  def command_type(%Command{params: %{__struct__: module}}) do
    module
    |> command_type()
  end

  def command_type(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.replace("Command", "")
  end

  def command_target(target) when is_atom(target) do
    target
    |> Atom.to_string()
    |> String.capitalize()
  end

  def target_active?(%Command{targets: targets}, target) do
    target in targets
  end

  def param_sliders(%Command{params: params}) do
    %{__struct__: struct} = params
    apply(struct, :defs, [])
  end

  def name(%ValueParam{name: name}) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.map(&String.replace(&1, "Ms", "[ms]"))
    |> Enum.join(" ")
  end
end

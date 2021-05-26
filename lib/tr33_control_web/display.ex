defmodule Tr33ControlWeb.Display do
  alias Tr33Control.Commands.{Command, ValueParam, EnumParam, Schemas, Preset}

  def command_type(%Command{} = command) do
    Command.type(command)
    |> humanize()
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

  def name(%ValueParam{name: name}), do: humanize(name)
  def name(%EnumParam{name: name}), do: humanize(name)

  def humanize(name) do
    name
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.map(&String.replace(&1, "Ms", "[ms]"))
    |> Enum.join(" ")
  end

  def current_preset(nil), do: "Load Preset"
  def current_preset(%Preset{name: name}), do: name

  def preset_option(%Preset{name: name, default: true}), do: "#{name} [default]"
  def preset_option(%Preset{name: name}), do: name
end

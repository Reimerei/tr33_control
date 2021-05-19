defmodule Tr33Control.Commands.LedStructure do
  @tr33_trunk_count 8
  @tr33_branch_count 12
  @keller_strip_count 10

  def strip_index_options() do
    case Application.fetch_env!(:tr33_control, :led_structure) do
      :tr33 ->
        [
          all: @tr33_trunk_count + @tr33_branch_count + 2,
          all_trunks: @tr33_trunk_count + @tr33_branch_count,
          all_branches: @tr33_trunk_count + @tr33_branch_count + 1
        ] ++
          Enum.map(0..(@tr33_trunk_count - 1), &{:"trunk_#{&1}", &1}) ++
          Enum.map(0..(@tr33_branch_count - 1), &{:"branch_#{&1}", &1 + @tr33_trunk_count})

      :keller ->
        [
          all: @keller_strip_count
        ] ++
          Enum.map(0..(@keller_strip_count - 1), &{:"strip_#{&1}", &1})

      :wand ->
        [strip: 0]
    end
  end

  def display_name() do
    Application.fetch_env!(:tr33_control, :led_structure)
    |> Atom.to_string()
    |> String.capitalize()
  end
end

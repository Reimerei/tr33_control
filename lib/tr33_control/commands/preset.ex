defmodule Tr33Control.Commands.Preset do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Tr33Control.Commands.{ColorPalette, Command}

  schema "presets2" do
    field :name, :string
    field :color_palette, ColorPalette
    embeds_many :commands, Command, on_replace: :delete

    timestamps()
  end

  def changeset(preset, params, commands, color_palette) do
    preset
    |> Changeset.cast(params, [:name])
    |> Changeset.put_change(:commands, commands)
    |> Changeset.put_change(:color_palette, color_palette)
    |> Changeset.validate_required([:name, :color_palette])
    |> Changeset.validate_length(:name, min: 2)
    |> Changeset.validate_length(:name, max: 42)
    |> Changeset.unique_constraint(:name)
  end
end

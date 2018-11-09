defmodule Tr33Control.Commands.Preset do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Tr33Control.Commands.CommandList

  schema "presets" do
    field :name, :string
    field :commands, CommandList

    timestamps()
  end

  def changeset(preset, params, commands) do
    preset
    |> Changeset.cast(params, [:name])
    |> Changeset.put_change(:commands, commands)
    |> Changeset.validate_required([:name])
    |> Changeset.validate_length(:name, min: 2)
    |> Changeset.validate_length(:name, max: 42)
    |> Changeset.unique_constraint(:name)
  end
end

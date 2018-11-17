defmodule Tr33Control.Commands.Preset do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Tr33Control.Commands.{ColorPalette, Command, Event}

  schema "presets2" do
    field :name, :string
    embeds_many :events, Event, on_replace: :delete
    embeds_many :commands, Command, on_replace: :delete

    timestamps()
  end

  def changeset(preset, params, commands, events) do
    preset
    |> Changeset.cast(params, [:name])
    |> Changeset.put_change(:commands, commands)
    |> Changeset.put_change(:events, events)
    |> Changeset.validate_required([:name])
    |> Changeset.validate_length(:name, min: 2)
    |> Changeset.validate_length(:name, max: 42)
    |> Changeset.unique_constraint(:name)
  end
end

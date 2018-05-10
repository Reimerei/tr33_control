defmodule Tr33Control.Commands.Preset do
  use Ecto.Schema
  alias Ecto.Changeset
  alias Tr33Control.Commands.Command

  @primary_key false
  embedded_schema do
    field :name, :string
    embeds_many :commands, Command
  end

  def changeset(command, params, commands) do
    command
    |> Changeset.cast(params, [:name])
    |> Changeset.put_embed(:commands, commands)
    |> Changeset.validate_required([:name])
  end
end

defmodule Tr33Control.Repo.Migrations.Presets do
  use Ecto.Migration

  def change do
    create table(:presets) do
      add :name, :string
      add :commands, :string
      timestamps()
    end

    create unique_index(:presets, [:name])
  end
end

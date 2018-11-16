defmodule Tr33Control.Repo.Migrations.Presets2 do
  use Ecto.Migration

  def change do
    create table(:presets2) do
      add :name, :string
      add :color_palette, :integer
      add :commands, {:array, :map}

      timestamps()
    end

    create unique_index(:presets2, [:name])

  end
end

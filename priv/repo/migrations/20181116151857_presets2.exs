defmodule Tr33Control.Repo.Migrations.Presets2 do
  use Ecto.Migration

  def change do
    create table(:presets2) do
      add :name, :string
      add :commands, {:array, :map}
      add :events, {:array, :map}

      timestamps()
    end

    create unique_index(:presets2, [:name])
  end
end

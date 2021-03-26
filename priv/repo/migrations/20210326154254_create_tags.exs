defmodule SecFilings.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :tag, :string, null: false
      add :value, :float, null: false
      add :contexts_id, references(:contexts, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:tags, :contexts_id)
    create unique_index(:tags, [:tag, :contexts_id])
  end
end

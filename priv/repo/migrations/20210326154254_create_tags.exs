defmodule SecFilings.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, options: "ROW_FORMAT=COMPRESSED") do
      add :tag, :string, null: false
      add :value, :float, null: false
      add :context_id, references(:contexts, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:tags, :context_id)
    create unique_index(:tags, [:tag, :context_id])
  end
end

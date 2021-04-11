defmodule SecFilings.Repo.Migrations.CreateContexts do
  use Ecto.Migration

  def change do
    create table(:contexts) do
      add :context_id, :text, null: false
      add :start_date, :date, null: false
      add :end_date, :date, null: false
      add :index_id, references(:index, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:contexts, [:index_id])
    create unique_index(:contexts, [:context_id, :index_id])
  end
end

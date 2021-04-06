defmodule SecFilings.Repo.Migrations.CreateParsedDocuments do
  use Ecto.Migration

  def change do
    create table(:parsed_documents, options: "ROW_FORMAT=COMPRESSED") do
      add :dt_processed, :date, null: false
      add :status, :boolean, null: false
      add :index_id, references(:index, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:parsed_documents, [:index_id])
  end
end

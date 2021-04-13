defmodule SecFilings.Repo.Migrations.CreateIndex do
  use Ecto.Migration

  def change do
    create table(:index) do
      add :cik, :integer, null: false
      add :company_name, :string, null: false
      add :form_type, :string, null: false
      add :date_filed, :date, null: false
      add :filename, :string, null: false
      add :status, :int2, default: -1, null: false

      # -1 for unprocessed, -3 for won't process (not 10k or 10q), -2 for started, but not stopped, 0 for started, 1 for success, 2 for no contexts, 3 for no tags, -99 for other

      timestamps()
    end

    create unique_index(:index, :filename)
    create index(:index, :status)
  end
end

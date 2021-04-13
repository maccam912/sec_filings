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
      # -1 for unprocessed, 0 for started, 1 for success, 2 for failure

      timestamps()
    end

    create unique_index(:index, :filename)
  end
end

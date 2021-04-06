defmodule SecFilings.Repo.Migrations.CreateIndex do
  use Ecto.Migration

  def change do
    create table(:index, options: "ROW_FORMAT=COMPRESSED") do
      add :cik, :integer, null: false
      add :company_name, :string, null: false
      add :form_type, :string, null: false
      add :date_filed, :date, null: false
      add :filename, :string, null: false

      timestamps()
    end

    create unique_index(:index, :filename)
  end
end

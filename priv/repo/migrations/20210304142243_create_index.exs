defmodule SecFilings.Repo.Migrations.CreateIndex do
  use Ecto.Migration

  def change do
    create table(:index) do
      add :cik, :integer
      add :company_name, :string
      add :form_type, :string
      add :date_filed, :date
      add :filename, :string

      timestamps()
    end

    create unique_index(:index, :filename)
  end
end

defmodule SecFilings.Repo.Migrations.CreateTagPairs do
  use Ecto.Migration

  def change do
    create table(:tag_pairs) do
      add :cik, :integer
      add :tag, :string
      add :value, :float
      add :start_date, :date
      add :end_date, :date

      timestamps()
    end

    create unique_index(:tag_pairs, [:cik, :tag, :start_date, :end_date])
  end
end

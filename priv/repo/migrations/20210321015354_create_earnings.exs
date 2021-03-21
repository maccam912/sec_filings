defmodule SecFilings.Repo.Migrations.CreateEarnings do
  use Ecto.Migration

  def change do
    create table(:earnings) do
      add :date, :date
      add :period, :integer
      add :earnings, :float
      add :cik, :integer

      timestamps()
    end

    create unique_index(:earnings, [:cik, :date, :period])
  end
end

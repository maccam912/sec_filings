defmodule SecFilings.Repo.Migrations.CreateSharesOutstanding do
  use Ecto.Migration

  def change do
    create table(:shares_outstanding) do
      add :cik, :integer
      add :date, :date
      add :shares_outstanding, :int8

      timestamps()
    end

    create unique_index(:shares_outstanding, [:cik, :date])
  end
end

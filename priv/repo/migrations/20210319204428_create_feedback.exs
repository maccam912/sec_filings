defmodule SecFilings.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback) do
      add :feedback, :text

      timestamps()
    end
  end
end

defmodule SecFilings.ParsedDocument do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parsed_documents" do
    field :dt_processed, :date
    belongs_to :index, SecFilings.Raw.Index

    timestamps()
  end

  @doc false
  def changeset(parsed_document, attrs) do
    parsed_document
    |> cast(attrs, [:dt_processed, :index_id])
    |> validate_required([:dt_processed, :index_id])
  end
end

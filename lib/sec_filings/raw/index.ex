defmodule SecFilings.Raw.Index do
  use Ecto.Schema
  import Ecto.Changeset

  schema "index" do
    field :cik, :integer
    field :company_name, :string
    field :form_type, :string
    field :date_filed, :date
    field :filename, :string
    has_one :parsed_documents, SecFilings.ParsedDocument
    has_many :contexts, SecFilings.Context

    timestamps()
  end

  @doc false
  def changeset(index, attrs) do
    index
    |> cast(attrs, [:cik, :company_name, :form_type, :date_filed, :filename])
    |> validate_required([:cik, :company_name, :form_type, :date_filed, :filename])
    |> unique_constraint(:filename, name: :index_filename_index)
  end
end

defmodule SecFilings.Context do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contexts" do
    field :context_id, :string
    field :end_date, :date
    field :start_date, :date
    belongs_to :index, SecFilings.Raw.Index
    has_many :tags, SecFilings.Tag

    timestamps()
  end

  @doc false
  def changeset(context, attrs) do
    context
    |> cast(attrs, [:context_id, :start_date, :end_date, :index_id])
    |> validate_required([:context_id, :start_date, :end_date, :index_id])
    |> unique_constraint(:contexts, name: :contexts_context_id_index_id_index)
  end
end

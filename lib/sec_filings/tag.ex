defmodule SecFilings.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :tag, :string
    field :value, :float
    belongs_to :contexts, SecFilings.Context

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:tag, :value, :context_id])
    |> validate_required([:tag, :value, :context_id])
    |> unique_constraint(:tags, name: :tags_tag_context_id_index)
  end
end

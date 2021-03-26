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
    |> cast(attrs, [:tag, :value, :contexts_id])
    |> validate_required([:tag, :value, :contexts_id])
    |> unique_constraint(:tags, name: :tags_tag_contexts_id_index)
  end
end

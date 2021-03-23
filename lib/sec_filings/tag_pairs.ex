defmodule SecFilings.TagPairs do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tag_pairs" do
    field :cik, :integer
    field :end_date, :date
    field :start_date, :date
    field :tag, :string
    field :value, :float

    timestamps()
  end

  @doc false
  def changeset(tag_pairs, attrs) do
    tag_pairs
    |> cast(attrs, [:cik, :tag, :value, :start_date, :end_date])
    |> validate_required([:cik, :tag, :value, :start_date, :end_date])
    |> unique_constraint([:cik, :tag, :start_date, :end_date],
      name: :tag_pairs_cik_tag_start_date_end_date_index
    )
  end
end

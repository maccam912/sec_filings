defmodule SecFilings.SharesOutstanding do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shares_outstanding" do
    field :cik, :integer
    field :date, :date
    field :shares_outstanding, :integer

    timestamps()
  end

  @doc false
  def changeset(shares_outstanding, attrs) do
    shares_outstanding
    |> cast(attrs, [:cik, :date, :shares_outstanding])
    |> validate_required([:cik, :date, :shares_outstanding])
    |> unique_constraint([:cik, :date], name: :shares_outstanding_cik_date_index)
  end
end

defmodule SecFilings.Earnings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "earnings" do
    field :date, :date
    field :earnings, :float
    field :period, :integer
    field :cik, :integer

    timestamps()
  end

  @doc false
  def changeset(earnings, attrs) do
    earnings
    |> cast(attrs, [:cik, :date, :period, :earnings])
    |> validate_required([:cik, :date, :period, :earnings])
    |> unique_constraint([:cik, :date, :period], name: :earnings_cik_date_period_index)
  end
end

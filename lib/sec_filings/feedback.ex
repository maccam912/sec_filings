defmodule SecFilings.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedback" do
    field :feedback, :string

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:feedback])
    |> validate_required([:feedback])
  end
end

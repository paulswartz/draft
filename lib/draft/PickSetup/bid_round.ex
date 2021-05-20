defmodule Draft.PickSetup.BidRound do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          bid_type: String.t(),
          booking_id: String.t(),
          division_description: String.t(),
          division_id: String.t(),
          process_id: String.t(),
          rank: integer(),
          rating_period_end_date: Date.t(),
          rating_period_start_date: Date.t(),
          round_closing_date: Date.t(),
          round_id: String.t(),
          round_opening_date: Date.t(),
          service_context: String.t() | nil
        }

  schema "bid_rounds" do
    field :bid_type, :string
    field :booking_id, :string
    field :division_description, :string
    field :division_id, :string
    field :process_id, :string
    field :rank, :integer
    field :rating_period_end_date, :date
    field :rating_period_start_date, :date
    field :round_closing_date, :date
    field :round_id, :string
    field :round_opening_date, :date
    field :service_context, :string

    timestamps()
  end

  @doc false
  def changeset(bid_round, attrs) do
    bid_round
    |> cast(attrs, [
      :process_id,
      :round_id,
      :round_opening_date,
      :round_closing_date,
      :bid_type,
      :rank,
      :service_context,
      :division_id,
      :division_description,
      :booking_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
    |> validate_required([
      :process_id,
      :round_id,
      :round_opening_date,
      :round_closing_date,
      :bid_type,
      :rank,
      :division_id,
      :division_description,
      :booking_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
  end
end

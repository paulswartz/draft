defmodule Draft.BidRound do
  @moduledoc """
  A Bid Round defines for a given division what type of selection employees are making (work vs. vacation), what period they will be picking preferences for, and when they will be able to pick.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @enforce_keys [
    :bid_type,
    :booking_id,
    :division_description,
    :process_id,
    :rank,
    :rating_period_end_date,
    :rating_period_start_date,
    :round_closing_date,
    :round_id,
    :round_opening_date
  ]

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

  @primary_key false
  schema "bid_rounds" do
    field :bid_type, :string
    field :booking_id, :string
    field :division_description, :string
    field :division_id, :string
    field :process_id, :string, primary_key: true
    field :rank, :integer
    field :rating_period_end_date, :date
    field :rating_period_start_date, :date
    field :round_closing_date, :date
    field :round_id, :string, primary_key: true
    field :round_opening_date, :date
    field :service_context, :string

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      process_id,
      round_id,
      round_opening_date,
      round_closing_date,
      bid_type,
      rank,
      service_context,
      division_id,
      division_description,
      booking_id,
      rating_period_start_date,
      rating_period_end_date
    ] = row

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      round_opening_date: ParsingHelpers.to_date(round_opening_date),
      round_closing_date: ParsingHelpers.to_date(round_closing_date),
      bid_type: bid_type,
      rank: String.to_integer(rank),
      service_context: service_context,
      division_id: division_id,
      division_description: division_description,
      booking_id: booking_id,
      rating_period_start_date: ParsingHelpers.to_date(rating_period_start_date),
      rating_period_end_date: ParsingHelpers.to_date(rating_period_end_date)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bid_round, attrs \\ %{}) do
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

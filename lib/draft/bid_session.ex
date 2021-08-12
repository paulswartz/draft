defmodule Draft.BidSession do
  @moduledoc """
  A bid session specifies what can be picked as part of a bid round. A bid round can have multiple sessions, though a vacation round will have only one session.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          process_id: String.t(),
          round_id: String.t(),
          session_id: String.t(),
          booking_id: String.t(),
          type: Draft.BidTypeEnum.t(),
          type_allowed: Draft.IntervalTypeEnum.t() | nil,
          service_context: String.t() | nil,
          scheduling_unit: String.t() | nil,
          division_id: String.t(),
          rating_period_start_date: Date.t(),
          rating_period_end_date: Date.t()
        }

  @primary_key false
  schema "bid_sessions" do
    field :process_id, :string, primary_key: true
    field :round_id, :string, primary_key: true
    field :session_id, :string, primary_key: true
    field :booking_id, :string
    field :type, Draft.BidTypeEnum
    field :type_allowed, Draft.IntervalTypeEnum
    field :service_context, :string
    field :scheduling_unit, :string
    field :division_id, :string
    field :rating_period_start_date, :date
    field :rating_period_end_date, :date

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      process_id,
      round_id,
      session_id,
      type,
      type_allowed,
      service_context,
      scheduling_unit,
      division_id,
      booking_id,
      rating_period_start_date,
      rating_period_end_date
    ] = row

    type_allowed_enum =
      case type_allowed do
        "Only weekly" -> :week
        "Only dated" -> :day
        nil -> nil
      end

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      session_id: session_id,
      booking_id: booking_id,
      type: Draft.BidTypeEnum.from_hastus(type),
      type_allowed: type_allowed_enum,
      service_context: service_context,
      scheduling_unit: scheduling_unit,
      division_id: division_id,
      rating_period_start_date: ParsingHelpers.to_date(rating_period_start_date),
      rating_period_end_date: ParsingHelpers.to_date(rating_period_end_date)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bid_group, attrs \\ %{}) do
    bid_group
    |> cast(attrs, [
      :process_id,
      :round_id,
      :session_id,
      :booking_id,
      :type,
      :type_allowed,
      :service_context,
      :scheduling_unit,
      :division_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
    |> validate_required([
      :process_id,
      :round_id,
      :session_id,
      :booking_id,
      :type,
      :division_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
  end
end

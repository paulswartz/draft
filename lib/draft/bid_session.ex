defmodule Draft.BidSession do
  @moduledoc """
  A bid session specifies what can be picked as part of a bid round. A bid round can have multiple sessions, though a vacation round will have only one session.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          process_id: String.t(),
          round_id: String.t(),
          session_id: String.t(),
          booking_id: String.t(),
          type: Draft.BidType.t(),
          type_allowed: Draft.IntervalType.t() | nil,
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
    field :type, Draft.BidType
    field :type_allowed, Draft.IntervalType
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

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      session_id: session_id,
      booking_id: booking_id,
      type: Draft.BidType.from_hastus(type),
      type_allowed: Draft.IntervalType.from_hastus_session_allowed(type_allowed),
      service_context: service_context,
      scheduling_unit: scheduling_unit,
      division_id: division_id,
      rating_period_start_date: ParsingHelpers.to_date(rating_period_start_date),
      rating_period_end_date: ParsingHelpers.to_date(rating_period_end_date)
    }
  end

  @spec vacation_interval(%{
          required(:round_id) => String.t(),
          required(:process_id) => String.t(),
          optional(atom()) => any()
        }) :: Draft.IntervalType.t() | nil
  @doc """
  Get the type of vacation allowed for the one vacation session in the given round.
  """
  def vacation_interval(%{round_id: round_id, process_id: process_id}) do
    Draft.Repo.one(
      from s in Draft.BidSession,
        where:
          s.round_id == ^round_id and
            s.process_id == ^process_id and
            s.type == :vacation,
        select: s.type_allowed
    )
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

defmodule Draft.RosterDay do
  @moduledoc """
  Information about a piece of work on a particular day. There will be one record for each roster
  and with a value for `day` that is a day of week (Monday, Tues, etc.) There may additionally
  be records where `day` is a particular date, indicating a schedule that differs from the base.
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          assignment: String.t(),
          booking_id: String.t(),
          crew_schedule_internal_id: integer(),
          day: String.t(),
          duty_internal_id: integer(),
          roster_id: String.t(),
          roster_position_id: String.t(),
          roster_position_internal_id: integer(),
          roster_set_id: String.t(),
          roster_set_internal_id: integer()
        }

  @primary_key false
  schema "roster_days" do
    field :assignment, :string
    field :booking_id, :string, primary_key: true
    field :crew_schedule_internal_id, :integer
    field :day, :string, primary_key: true
    field :duty_internal_id, :integer
    field :roster_id, :string, primary_key: true
    field :roster_position_id, :string
    field :roster_position_internal_id, :integer, primary_key: true
    field :roster_set_id, :string
    field :roster_set_internal_id, :integer, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      booking_id,
      roster_set_id,
      roster_set_internal_id,
      roster_id,
      roster_position_id,
      roster_position_internal_id,
      day,
      assignment,
      duty_internal_id,
      crew_schedule_internal_id
    ] = row

    %__MODULE__{
      booking_id: booking_id,
      roster_set_id: roster_set_id,
      roster_set_internal_id: String.to_integer(roster_set_internal_id),
      roster_id: roster_id,
      roster_position_id: roster_position_id,
      roster_position_internal_id: String.to_integer(roster_position_internal_id),
      day: day,
      assignment: assignment,
      duty_internal_id: Draft.ParsingHelpers.to_int(duty_internal_id),
      crew_schedule_internal_id: String.to_integer(crew_schedule_internal_id)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(roster_day, attrs) do
    roster_day
    |> cast(attrs, [
      :booking_id,
      :roster_set_id,
      :roster_set_internal_id,
      :roster_id,
      :roster_position_id,
      :roster_position_internal_id,
      :day,
      :assignment,
      :duty_internal_id,
      :crew_schedule_internal_id
    ])
    |> validate_required([
      :booking_id,
      :roster_set_id,
      :roster_set_internal_id,
      :roster_id,
      :roster_position_id,
      :roster_position_internal_id,
      :day,
      :assignment,
      :duty_internal_id,
      :crew_schedule_internal_id
    ])
  end
end

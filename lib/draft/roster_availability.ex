defmodule Draft.RosterAvailability do
  @moduledoc """
  Represent a roster that is available to be picked in a session
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          booking_id: String.t(),
          is_available: boolean(),
          roster_id: String.t(),
          roster_set_id: String.t(),
          roster_set_internal_id: integer(),
          session_id: String.t(),
          work_off_ratio: String.t()
        }

  @primary_key false
  schema "roster_availabilities" do
    field :booking_id, :string, primary_key: true
    field :is_available, :boolean
    field :roster_id, :string, primary_key: true
    field :roster_set_id, :string
    field :roster_set_internal_id, :integer, primary_key: true
    field :session_id, :string, primary_key: true
    field :work_off_ratio, :string

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      booking_id,
      session_id,
      roster_set_id,
      roster_set_internal_id,
      roster_id,
      work_off_ratio,
      is_available
    ] = row

    %__MODULE__{
      booking_id: booking_id,
      session_id: session_id,
      roster_set_id: roster_set_id,
      roster_set_internal_id: String.to_integer(roster_set_internal_id),
      roster_id: roster_id,
      # TODO -- enum?
      work_off_ratio: work_off_ratio,
      is_available: Draft.ParsingHelpers.to_boolean(is_available)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(roster_availability, attrs) do
    roster_availability
    |> cast(attrs, [
      :booking_id,
      :session_id,
      :roster_set_id,
      :roster_set_internal_id,
      :roster_id,
      :work_off_ratio,
      :is_available
    ])
    |> validate_required([
      :booking_id,
      :session_id,
      :roster_set_id,
      :roster_set_internal_id,
      :roster_id,
      :work_off_ratio,
      :is_available
    ])
  end
end

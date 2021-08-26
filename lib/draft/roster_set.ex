defmodule Draft.RosterSet do
  @moduledoc """
  All work in a scheduling unit that can be picked as part of a session
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          booking_id: String.t(),
          roster_set_id: String.t(),
          roster_set_internal_id: integer(),
          scenario: integer(),
          scheduling_unit: String.t(),
          service_context: String.t(),
          session_id: String.t()
        }

  @primary_key false
  schema "roster_sets" do
    field :booking_id, :string, primary_key: true
    field :roster_set_id, :string
    field :roster_set_internal_id, :integer, primary_key: true
    field :scenario, :integer
    field :scheduling_unit, :string, primary_key: true
    field :service_context, :string
    field :session_id, :string

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      booking_id,
      session_id,
      scheduling_unit,
      roster_set_id,
      roster_set_internal_id,
      scenario,
      service_context
    ] = row

    %__MODULE__{
      booking_id: booking_id,
      session_id: session_id,
      scheduling_unit: scheduling_unit,
      roster_set_id: roster_set_id,
      roster_set_internal_id: String.to_integer(roster_set_internal_id),
      scenario: String.to_integer(scenario),
      service_context: service_context
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(roster_set, attrs) do
    roster_set
    |> cast(attrs, [
      :booking_id,
      :session_id,
      :scheduling_unit,
      :roster_set_id,
      :roster_set_internal_id,
      :scenario,
      :service_context
    ])
    |> validate_required([
      :booking_id,
      :session_id,
      :scheduling_unit,
      :roster_set_id,
      :roster_set_internal_id,
      :scenario,
      :service_context
    ])
  end
end

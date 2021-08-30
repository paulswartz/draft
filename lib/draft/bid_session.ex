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
          :round_id => String.t(),
          :process_id => String.t(),
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

  @doc """
  Get the single session for the associated round
  """
  @spec single_session_for_round(%{
          :round_id => String.t(),
          :process_id => String.t(),
          optional(atom()) => any()
        }) :: t()
  def single_session_for_round(round) do
    Draft.Repo.one!(
      from s in Draft.BidSession,
        where:
          s.round_id == ^round.round_id and
            s.process_id == ^round.process_id
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

  @spec calculate_point_of_equivalence(t()) :: %{
          amount_to_force: integer(),
          employees_to_force: [{String, t(), integer()}],
          has_poe_been_reached: boolean()
        }
  @doc """
  Return whether or not the point of equivalence has been hit yet in the given vacation week
  session, and which operators would be forced in order to fill the desired amount of quota to
  force assuming that no remaining operators want to voluntarily take vacation.
  """
  def calculate_point_of_equivalence(
        %{
          type: :vacation,
          type_allowed: :week,
          rating_period_start_date: start_date,
          rating_period_end_date: end_date
        } = session
      ) do
    # Temporarily forcing all remaining quota -- in the future, Draft will
    # Get the amount to force as input.

    quota_to_force = Draft.DivisionVacationWeekQuota.remaining_quota(session)

    employees_desc = Draft.EmployeeRanking.all_remaining_employees(session, :desc)

    calculate_point_of_equivalence(quota_to_force, employees_desc, start_date, end_date)
  end

  defp calculate_point_of_equivalence(quota_to_force, employees_desc, start_date, end_date) do
    {employees_to_force, _acc_employee_quota} =
      Enum.reduce_while(employees_desc, {[], 0}, fn %{employee_id: employee_id} = employee_ranking,
                                                    {acc_employees_to_force, acc_quota} ->
        employee_quota =
          Draft.EmployeeVacationQuota.week_quota(
            employee_ranking,
            start_date,
            end_date
          )

        if employee_quota + acc_quota < quota_to_force do
          {:cont,
           {[{employee_id, employee_quota} | acc_employees_to_force], acc_quota + employee_quota}}
        else
          emp_quota_to_force = quota_to_force - acc_quota

          {:halt,
           {[{employee_id, emp_quota_to_force} | acc_employees_to_force],
            acc_quota + emp_quota_to_force}}
        end
      end)

    %{
      amount_to_force: quota_to_force,
      has_poe_been_reached: length(employees_to_force) == length(employees_desc),
      employees_to_force: employees_to_force
    }
  end
end

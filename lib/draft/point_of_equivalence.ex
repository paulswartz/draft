defmodule Draft.PointOfEquivalence do
  @moduledoc """
  The Point of Equivalence (POE) is when the amount of weeks available in a pick equals
  the amount of vacation weeks the remaining set of employees has. Once POE has been reached,
  Forcing will begin
  """

  defstruct [:amount_to_force, :employees_to_force, :has_poe_been_reached]

  @type t :: %__MODULE__{
          amount_to_force: integer(),
          employees_to_force: [{String.t(), integer()}],
          has_poe_been_reached: boolean()
        }

  @spec calculate(Draft.BidSession.t()) :: t()
  @doc """
  Return whether or not the point of equivalence has been hit yet in the given vacation week
  session, and which operators would be forced in order to fill the desired amount of quota to
  force assuming that no remaining operators want to voluntarily take vacation.
  The returned `employees_to_force` will be in order of rank ascending, with the
  most senior operator listed first.
  """
  def calculate(
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

    calculate(quota_to_force, employees_desc, start_date, end_date)
  end

  @spec calculate_during_distribution(
          Draft.BidSession.t(),
          [Draft.EmployeeRanking.t()],
          integer()
        ) :: t()
  @doc """
  Calculate the point of equivalence for the given list of employees, taking into consideration
  The amount of vacation that has already been distributed but is not accounted for in the
  division quotas. The returned `employees_to_force` will be in order of rank ascending, with the
  most senior operator listed first.
  """
  def calculate_during_distribution(
        session,
        employees_to_force,
        already_distributed_vacation_count
      ) do
    employees_desc = Enum.sort_by(employees_to_force, &{&1.group_number, &1.rank}, :desc)

    quota_to_force =
      Draft.DivisionVacationWeekQuota.remaining_quota(session) -
        already_distributed_vacation_count

    calculate(quota_to_force, employees_desc, session.start_date, session.end_date)
  end

  defp calculate(quota_to_force, employees_desc, start_date, end_date) do
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

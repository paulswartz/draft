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

    %__MODULE__{
      amount_to_force: quota_to_force,
      has_poe_been_reached: length(employees_to_force) == length(employees_desc),
      employees_to_force: employees_to_force
    }
  end
end

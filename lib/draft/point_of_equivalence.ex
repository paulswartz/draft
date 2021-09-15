defmodule Draft.PointOfEquivalence do
  @moduledoc """
  The Point of Equivalence (POE) is when the amount of weeks available in a pick equals
  the amount of vacation weeks the remaining set of employees has. Once POE has been reached,
  Forcing will begin
  """

  defstruct [:amount_to_force, :employees_to_force, :reached?]

  @type t :: %__MODULE__{
          amount_to_force: integer(),
          employees_to_force: [{String.t(), integer()}],
          reached?: boolean()
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

    session
    |> Draft.EmployeeRanking.all_remaining_employees(:desc)
    |> Enum.map(&Draft.EmployeeVacationQuotaSummary.get(&1, start_date, end_date, :week))
    |> Enum.map(
      &{&1.employee_id,
       Draft.JobClassHelpers.weeks_from_minutes(&1.total_available_minutes, &1.job_class)}
    )
    |> calculate_helper(quota_to_force)
  end

  @spec calculate([Draft.EmployeeVacationQuotaSummary.t()], non_neg_integer()) :: t()
  @doc """
  Return whether or not the point of equivalence has been hit yet among the given list
  of employees, and which operators would be forced in order to fill the given amount of quota to
  force assuming that no remaining operators want to voluntarily take vacation.
  The returned `employees_to_force` will be in order of rank ascending, with the
  most senior operator listed first.
  """
  def calculate(_employees, 0) do
    %__MODULE__{
      amount_to_force: 0,
      reached?: false,
      employees_to_force: []
    }
  end

  def calculate(employees, quota_to_force) do
    employees
    |> Enum.sort_by(&{&1.group_number, &1.rank}, :desc)
    |> Enum.map(
      &{&1.employee_id,
       Draft.JobClassHelpers.weeks_from_minutes(&1.total_available_minutes, &1.job_class)}
    )
    |> calculate_helper(quota_to_force)
  end

  @spec calculate_helper([{String.t(), non_neg_integer()}], non_neg_integer()) :: t()
  defp calculate_helper(employees_desc, quota_to_force) do
    {employees_to_force, _acc_employee_quota} =
      Enum.reduce_while(employees_desc, {[], 0}, fn {employee_id, employee_quota},
                                                    {acc_employees_to_force, acc_quota} ->
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
      reached?: length(employees_to_force) == length(employees_desc),
      employees_to_force: employees_to_force
    }
  end

  @spec amount_to_force_employee(Draft.BidSession.t(), String.t()) :: non_neg_integer() | nil
  @doc """
  How much vacation the given operator will be forced, if it is known (poe has been reached)
  For days sessions, always returns nil, since POE is not calculated for vacation days.
  """
  def amount_to_force_employee(%{type: :vacation, type_allowed: :day}, _employee_id) do
    nil
  end

  def amount_to_force_employee(%{type: :vacation, type_allowed: :week} = session, employee_id) do
    poe = calculate(session)

    if poe.reached? do
      poe.employees_to_force
      |> Map.new()
      |> Map.get(employee_id)
    else
      nil
    end
  end
end

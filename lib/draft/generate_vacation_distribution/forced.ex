defmodule Draft.GenerateVacationDistribution.Forced do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to all employees in the given group,
  ensuring that it will be possible to force all remaining employees to take vacation as well.
  """
  import Ecto.Query
  alias Draft.DivisionVacationWeekQuota
  alias Draft.Repo
  alias Draft.VacationDistribution
  require Logger

  @type acc_vacation_distributions() :: %{Date.t() => MapSet.t(VacationDistribution.t())}

  @spec generate_for_group(%{
          round_id: String.t(),
          process_id: String.t(),
          group_number: integer()
        }) :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Generate vacation assignments that force all employees in the given group (and all remaining
  groups after them) to use all of their remaining full vacation weeks. Assignments are made in
  seniority order, so the most senior operator is awarded vacation as long as it is possible
  force all remaining operators to use all their vacation time.
  """
  def generate_for_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
    group =
      Repo.get_by(Draft.BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    if group do
      round = Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      # The use of `get_all_operators_in_or_after_group` here is a temporary simplification;
      # We ultimately won't need to force all operators in the specified group & all following.
      # We will only need to generate distributions for the curent group, ensuring that the subset
      # of the least senior operators who will need to be forced can still be forced in a valid
      # way.
      generate_distributions_for_all(round, get_all_operators_in_or_after_group(group))
    else
      {:error,
       "No group found with round_id: #{round_id}, process_id: #{process_id}, group_number: #{
         group_number
       }"}
    end
  end

  defp get_all_operators_in_or_after_group(%{
         round_id: round_id,
         process_id: process_id,
         group_number: group_number
       }) do
    Repo.all(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number >= ^group_number,
        order_by: [asc: [e.group_number, e.rank]]
    )
  end

  # Generate vacation distributions for all specified employees.
  @spec generate_distributions_for_all(
          Draft.BidRound.t(),
          [Draft.EmployeeRanking.t()],
          acc_vacation_distributions()
        ) :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  defp generate_distributions_for_all(round, employees, acc_vacation_to_distribute \\ %{})

  # Base case: No employees to distribute to - return the accumulated list of distributions.
  defp generate_distributions_for_all(_round, [], acc_vacation_to_distribute) do
    {:ok, distributions_from_acc_vacation(acc_vacation_to_distribute)}
  end

  defp generate_distributions_for_all(round, employees, acc_vacation_to_distribute) do
    [first_emp | remaining_emps] = employees

    # The list of possible vacation distributions that can be made are unique to each employee,
    # based what has already been distributed that isn't accounted for in quotas
    # (`acc_vacation_to_distribute`), the previous vacation selections that employee made in the
    # annual pick, their work schedule, and will be uniquely ordered based on their preferences.

    # We only evaluate the possible assignments for the first employee in the list, since the
    # possible assignments for all remaining employees will be dependent on the assignments made
    # to prior employees. Once distributions have been generated for the quota of the first
    # employee, `generate_distributions_for_all` will be recursively called on the list of
    # remaining employees.
    possible_assignments =
      all_vacation_available_to_employee(
        round,
        first_emp,
        :week,
        count_by_start_date(acc_vacation_to_distribute)
      )

    case calculated_quota(round, first_emp, :week) do
      {:ok, quota} ->
        generate_distributions(
          round,
          %{
            quota: quota,
            possible_assignments: possible_assignments,
            employee_id: first_emp.employee_id
          },
          remaining_emps,
          acc_vacation_to_distribute
        )

      {:error, error} ->
        {:error, error}
    end
  end

  # Generate vacation distributions for the current employee, and
  # Recurse on all remaining employees.
  defp generate_distributions(
         round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       )

  # Base case: the current employee has been fully distributed to,
  # and there are no remaining employees to distribute to,
  # indicating that generating distributions has been successful.
  defp generate_distributions(
         _round,
         %{quota: %{remaining: 0}} = _current_employee,
         [],
         acc_vacation_to_distribute
       ) do
    {:ok, distributions_from_acc_vacation(acc_vacation_to_distribute)}
  end

  # Base case: completed distribution to current employee (depleted their quota),
  # recurse on all remaining employees
  defp generate_distributions(
         round,
         %{quota: %{remaining: 0}} = _current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       ) do
    generate_distributions_for_all(round, remaining_employees, acc_vacation_to_distribute)
  end

  # Base case: If there are no more available vacation times to distribute to the curent employee,
  # (And their remaining quota isn't 0 based on above pattern matching)
  # return an error -- there is not a valid way to assign them vacation time
  defp generate_distributions(
         _round,
         %{possible_assignments: []} = _current_employee,
         _remaining_employees,
         _acc_vacation_to_distribute
       ) do
    {:error, :no_schedule_found}
  end

  # Normal case: For each possible vacation distribution for the current employee,
  # try to assign it to them & reduce their quota by one.
  # call recursively to continue fully assigning vacation to the first employee and all
  # remaining employees. If an error is reached in assignment, try assigning the next available
  # vacation instead.
  defp generate_distributions(
         round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       ) do
    [next_assignment | remaining_assignments] = current_employee.possible_assignments

    case generate_distributions(
           round,
           %{
             employee_id: current_employee.employee_id,
             # Decrement the employee's quota
             quota: %{remaining: current_employee.quota.remaining - 1},
             possible_assignments: remaining_assignments
           },
           remaining_employees,
           add_distribution_to_acc(acc_vacation_to_distribute, next_assignment)
         ) do
      {:ok, distributions} ->
        {:ok, distributions}

      {:error, _} ->
        # If there is no valid schedule produced by assigning this employee their first possible
        # assignment, recurse with the next possible assignments
        generate_distributions(
          round,
          Map.put(current_employee, :possible_assignments, remaining_assignments),
          remaining_employees,
          acc_vacation_to_distribute
        )
    end
  end

  @spec add_distribution_to_acc(acc_vacation_distributions(), VacationDistribution.t()) ::
          acc_vacation_distributions()
  defp add_distribution_to_acc(acc_vacation_to_distribute, new_distribution) do
    Map.update(
      acc_vacation_to_distribute,
      new_distribution.start_date,
      MapSet.new([new_distribution]),
      fn all_assignments_for_date ->
        MapSet.put(all_assignments_for_date, new_distribution)
      end
    )
  end

  @spec calculated_quota(
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t()
        ) ::
          {:ok, %{remaining: integer()}}
          | {:error, :multiple_vacation_balances | :no_vacation_balance}
  # Get the given employee's vacation quota for the specified interval type. This currently only
  # returns information about their whole-unit quota (no partial) In the future it could contain
  # information about their minimum quota and maximum desired quota
  # (a preference that is user-set). This will return an error if the employee has multiple quotas
  # specified covering the rating period for the given round, or if their quota record is missing.
  defp calculated_quota(round, employee, :week) do
    employee_balances =
      Repo.all(
        from q in Draft.EmployeeVacationQuota,
          where:
            q.employee_id == ^employee.employee_id and
              (q.interval_start_date <= ^round.rating_period_start_date and
                 q.interval_end_date >= ^round.rating_period_end_date)
      )

    case employee_balances do
      [] -> {:error, :no_vacation_balance}
      [balance] -> {:ok, calculated_quota_from_balance(balance, employee.job_class, :week)}
      _multiple_balances -> {:error, :multiple_vacation_balances}
    end
  end

  @spec calculated_quota_from_balance(
          Draft.EmployeeVacationQuota.t(),
          String.t(),
          Draft.IntervalTypeEnum.t()
        ) :: %{remaining: integer()}
  defp calculated_quota_from_balance(employee_balance, job_class, :week) do
    max_minutes = employee_balance.maximum_minutes

    num_hours_per_day = Draft.JobClassHelpers.num_hours_per_day(job_class)

    # Cap weeks by the maximum number of paid vacation minutes an operator has remaining
    max_weeks = min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

    %{remaining: max_weeks}
  end

  @spec all_vacation_available_to_employee(
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t(),
          %{
            Date.t() => integer()
          }
        ) :: [VacationDistribution.t()]
  # Get all vacation available to the given employee,
  # Based on what is available in their division quota & the distributions not reflected in quota,
  # and vacations they have previously selected. The returned list of vacation distributions
  # Will be ordered from most preferrable to least preferrable.
  # (the latest possible vacation will be first in the list)
  defp all_vacation_available_to_employee(
         round,
         employee,
         :week = interval_type,
         distributions_not_reflected_in_quota
       ) do
    round
    |> DivisionVacationWeekQuota.available_quota(employee)
    |> Enum.map(fn original_quota ->
      %DivisionVacationWeekQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(distributions_not_reflected_in_quota, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
    |> Enum.map(fn q ->
      %VacationDistribution{
        employee_id: employee.employee_id,
        interval_type: interval_type,
        start_date: q.start_date,
        end_date: q.end_date
      }
    end)
  end

  @spec count_by_start_date(acc_vacation_distributions()) :: %{Date.t() => integer()}
  defp count_by_start_date(acc_vacation_to_distriubte) do
    Map.new(acc_vacation_to_distriubte, fn {start_date, distributions} ->
      {start_date, MapSet.size(distributions)}
    end)
  end

  @spec distributions_from_acc_vacation(acc_vacation_distributions()) :: [
          VacationDistribution.t()
        ]
  defp distributions_from_acc_vacation(acc_vacation_to_distribute) do
    Enum.flat_map(acc_vacation_to_distribute, fn {_start_date, distributions} ->
      distributions
    end)
  end
end

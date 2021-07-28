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

  @type vacation_interval() :: %{
          start_date: Date.t(),
          end_date: Date.t(),
          interval_type: Draft.IntervalTypeEnum.t()
        }

  @type acc_vacation_interval() :: %{vacation_interval() => MapSet.t(String.t())}

  @spec generate_for_group(%{
          round_id: String.t(),
          process_id: String.t(),
          group_number: integer()
        }) :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Generate vacation assignments that force all employees in the given group (and all remaining groups after them) to use all of their remaining full vacation weeks.vacation_interval()
  Assignments are made in seniority order, so the most senior operator is awarded vacation so long as it is possible force all remaining operators to use all their vacation time.
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

      # In the future, we wouldn't need to evaluate for all operators in all following groups; only the ones that
      # are determined to need forcing
      generate_distributions_for_all(round, get_all_operators_in_or_after_group(group))
    else
      {:error,
       "No group found with round_id: #{round_id}, process_id: #{process_id}, group_number: #{
         group_number
       }"}
    end
  end

  defp generate_distributions_for_all(round, employees, acc_vacation_to_distribute \\ %{})

  defp generate_distributions_for_all(_round, [], _acc_vacation_to_distribute) do
    {:error, :no_operators_found}
  end

  defp generate_distributions_for_all(round, employees, acc_vacation_to_distribute) do
    [first_emp | remaining_emps] = employees

    case calculated_quota(round, first_emp, :week) do
      {:ok, quota} ->
        generate_distributions(
          round,
          %{
            quota: quota,
            possible_assignments:
              all_vacation_available_to_employee(
                count_by_start_date(acc_vacation_to_distribute),
                round,
                first_emp,
                :week
              ),
            employee_id: first_emp.employee_id
          },
          remaining_emps,
          acc_vacation_to_distribute
        )

      {:error, error} ->
        {:error, error}
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

  defp generate_distributions(
         round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       )

  defp generate_distributions(
         round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       )
       when current_employee.quota.remaining == 0 and remaining_employees != [] do
    # Completed distribution for the current employee. Continue distribution for the remaining employees
    generate_distributions_for_all(round, remaining_employees, acc_vacation_to_distribute)
  end

  defp generate_distributions(
         _round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       )
       when current_employee.quota.remaining == 0 and remaining_employees == [] do
    # Completed distribution for the current employee and no remaining employees -
    # all assignments generated successfully
    if is_invalid_schedule(current_employee) do
      {:error, :invalid_schedule}
    else
      {:ok, distributions_from_acc_vacation_intervals(acc_vacation_to_distribute)}
    end
  end

  defp generate_distributions(
         round,
         current_employee,
         remaining_employees,
         acc_vacation_to_distribute
       ) do
    Enum.reduce_while(
      Enum.with_index(current_employee.possible_assignments),
      {:error, :no_schedule_found},
      fn {assignment, index}, acc ->
        {_previously_explored_assignments, remaining_assignments} =
          Enum.split(current_employee.possible_assignments, index + 1)

        result =
          generate_distributions(
            round,
            %{
              employee_id: current_employee.employee_id,
              quota: %{remaining: current_employee.quota.remaining - 1},
              possible_assignments: remaining_assignments
            },
            remaining_employees,
            Map.update(
              acc_vacation_to_distribute,
              assignment,
              MapSet.new([current_employee.employee_id]),
              fn e ->
                MapSet.put(e, current_employee.employee_id)
              end
            )
          )

        case result do
          {:ok, vacation_distributions} -> {:halt, {:ok, vacation_distributions}}
          {:error, _any} -> {:cont, acc}
        end
      end
    )
  end

  defp is_invalid_schedule(current_emp) do
    ## Schedule is invalid if employee needs to be assigned more time, but there are no valid assignments remaining.
    current_emp.quota.remaining > 0 and current_emp.possible_assignments == []
  end

  @spec calculated_quota(
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t()
        ) :: {:ok, %{:remaining => integer()}} | {:error, :multiple_vacation_balances | :no_vacation_balance}
  defp calculated_quota(round, employee, :week) do
    # For now, only getting balance if the balance interval covers the entire rating period.
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
          %{
            Date.t() => integer()
          },
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t()
        ) :: [vacation_interval()]
  defp all_vacation_available_to_employee(
         distributions_in_run_by_date,
         round,
         employee,
         :week = interval_type
       ) do
    round
    |> DivisionVacationWeekQuota.available_quota(employee)
    |> Enum.map(fn original_quota ->
      %DivisionVacationWeekQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(distributions_in_run_by_date, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
    |> Enum.map(fn q ->
      %{start_date: q.start_date, end_date: q.end_date, interval_type: interval_type}
    end)
  end

  @spec count_by_start_date(acc_vacation_interval()) :: %{Date.t() => integer()}
  defp count_by_start_date(acc_vacation_to_distriubte) do
    Enum.into(acc_vacation_to_distriubte, %{}, fn {vacation, emps} ->
      {vacation.start_date, MapSet.size(emps)}
    end)
  end

  @spec distributions_from_acc_vacation_intervals(acc_vacation_interval()) :: [VacationDistribution.t()]
  defp distributions_from_acc_vacation_intervals(acc_vacation_to_distribute) do

    Enum.flat_map(acc_vacation_to_distribute, fn {vac, employees} ->
      Enum.map(employees, &distribution_from_interval(&1, vac))
    end)
  end

  defp distribution_from_interval(employee_id, vacation_interval) do
    Logger.info(
      "assigned #{vacation_interval.interval_type} - #{vacation_interval.start_date} - #{
        vacation_interval.end_date
      }"
    )

    %VacationDistribution{
      employee_id: employee_id,
      interval_type: vacation_interval.interval_type,
      start_date: vacation_interval.start_date,
      end_date: vacation_interval.end_date
    }
  end
end

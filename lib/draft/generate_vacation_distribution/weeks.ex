defmodule Draft.GenerateVacationDistribution.Weeks do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to the given employee
  """
  alias Draft.DivisionVacationWeekQuota
  alias Draft.VacationDistribution
  import Ecto.Query
  alias Draft.Repo
  require Logger

  @spec generate(
          integer(),
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t()
        ) :: [VacationDistribution.t()]

  @doc """
  generate a list of vacation weeks for an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, only vacation weeks earned prior to the anniversary are distributed.
  """
  def generate(
        distribution_run_id,
        round,
        employee_ranking,
        interval_type
      )

  def generate(
        distribution_run_id,
        round,
        employee_ranking,
        :week = interval_type
      ) do
    calculated_quota = calculated_quota(round, employee_ranking, interval_type)

    distributions_in_run_by_date =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(
        distribution_run_id,
        interval_type
      )

    preferences =
      Draft.EmployeeVacationPreferenceSet.get_latest_preferences(
        round.process_id,
        round.round_id,
        employee_ranking.employee_id,
        interval_type
      )

    # In the future for forcing algorithm, the vacation available would be determined by
    # whether or not the employee is being forced. If they are forced, it is all vacation available to the employee, ordered by preference, then desc.
    # If they are not forced, only their available preferences would be used.
    vacation_available_to_employee =
      if preferences == [] do
        all_vacation_available_to_employee(
          distributions_in_run_by_date,
          round,
          employee_ranking,
          interval_type
        )
      else
        available_preferences(
          preferences,
          distributions_in_run_by_date,
          round,
          employee_ranking,
          interval_type
        )
      end

    generate_distributions(
      distribution_run_id,
      round,
      employee_ranking.employee_id,
      calculated_quota,
      vacation_available_to_employee
    )
  end

  def distribute_vacation_to_group(%{
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

      case Repo.all(
             from e in Draft.EmployeeRanking,
               where:
                 e.round_id == ^group.round_id and e.process_id == ^group.process_id and
                   e.group_number >= ^group.group_number,
               order_by: [asc: [e.group_number, e.rank]]
           ) do
        [first_emp, remaining_emps] ->
          distribute_for_group(
            round,
            %{
              remaining_quota: calculated_quota(round, first_emp, :week),
              possible_assignments:
                all_vacation_available_to_employee(%{}, round, first_emp, :week),
              employee_id: first_emp.employee_id
            },
            remaining_emps,
            %{}
          )

        [first_emp] ->
          distribute_for_group(
            round,
            %{
              remaining_quota: calculated_quota(round, first_emp, :week),
              possible_assignments:
                all_vacation_available_to_employee(%{}, round, first_emp, :week),
              employee_id: first_emp.employee_id
            },
            [],
            %{}
          )
      end
    else
      {:error, "No group found with
round_id: #{round_id},
process_id: #{process_id},
group_number: #{group_number}
"}
    end
  end

  defp distribute_for_group(
         round,
         %{
           remaining_quota: remaining_quota,
           possible_assignments: possible_assignments,
           employee_id: employee_id
         } = current_employee,
         remaining_employees,
         assignments
       ) do
    Logger.error("Distributing for current employee #{employee_id}")
    Logger.error("Assignments still remaining: #{inspect(possible_assignments)}")
    if is_completed_schedule(remaining_quota, remaining_employees) do
      Logger.error("Completed")
      {:ok, assignments}

    else
      if is_invalid_schedule(current_employee) do
        {:error, :invalid_schedule}
      else

      if elem(current_employee.remaining_quota, 0) == 0 do
        Logger.error("Remaining quota is 0")
        case remaining_employees do
          [first_emp, remaining_emps] ->
            distribute_for_group(
              round,
              %{
                remaining_quota: calculated_quota(round, first_emp, :week),
                possible_assignments:
                  all_vacation_available_to_employee(
                    Enum.into(assignments, %{}, fn {date, emps} -> {date, MapSet.size(emps)} end),
                    round,
                    first_emp,
                    :week
                  ),
                employee_id: first_emp.employee_id
              },
              remaining_emps,
              assignments
            )

          first_emp ->
            distribute_for_group(
              round,
              %{
                remaining_quota: calculated_quota(round, first_emp, :week),
                possible_assignments:
                  all_vacation_available_to_employee(
                    Enum.into(assignments, %{}, fn {date, emps} -> {date, MapSet.size(emps)} end),
                    round,
                    first_emp,
                    :week
                  ),
                employee_id: first_emp.employee_id
              },
              [],
              assignments
            )
        end
      else
        # reduce while?
        Enum.reduce_while(Enum.with_index(possible_assignments), {:error, :no_schedule_found}, fn {o, index}, acc ->
          {_assignments_in_previous_branch, remaining_assignments} =
            Enum.split(possible_assignments, index + 1)
          Logger.error("Distributing #{inspect(o)}")

          result = distribute_for_group(
            round,
            %{
              employee_id: employee_id,
              # TODO -- doesn't account for anniversary time at all
              remaining_quota: {elem(remaining_quota, 0) - 1, elem(remaining_quota, 1)},
              possible_assignments: remaining_assignments
            },
            remaining_employees,
            Map.update(assignments, o.start_date, MapSet.new([employee_id]), fn e ->
              MapSet.put(e, employee_id)
            end)
          )

          case result do
            {:ok, assignments } -> {:halt, {:ok, assignments}}
            {:error, _any} -> {:cont, acc}
          end
        end)
      end
    end
    end


  end

  defp is_invalid_schedule(current_emp) do
    ## TODO: Add other checks?
    elem(current_emp.remaining_quota, 0) > 0 and length(current_emp.possible_assignments) == 0
  end

  defp is_completed_schedule(quota, employees) do
    employees == [] and elem(quota, 0) == 0
    ## TODO: Add checks to make sure quota is as expected?
  end

  defp generate_distributions(
         distribution_run_id,
         round,
         employee_id,
         calcualted_quota,
         vacation_available_to_employee
       )

  defp generate_distributions(
         _distribution_run_id,
         _round,
         employee_id,
         {quota, nil},
         vacation_available_to_employee
       ) do
    vacation_available_to_employee
    # With the full forcing algorithm, instead of taking the first X possible assignments, one assignment will be made,
    # Then a recursive call will be made to make the next assignment, and so on for the remaining employees that will be forced.
    |> Enum.take(quota)
    |> Enum.map(fn v -> generate_distribution(employee_id, v) end)
  end

  defp generate_distributions(
         _distribution_run_id,
         round,
         employee_id,
         {quota,
          %{
            anniversary_date: anniversary_date,
            anniversary_weeks: anniversary_weeks
          }},
         vacation_available_to_employee
       ) do
    case Draft.Utils.compare_date_to_range(
           anniversary_date,
           round.rating_period_start_date,
           round.rating_period_end_date
         ) do
      :before_range ->
        vacation_available_to_employee
        |> Enum.take(quota)
        |> Enum.map(fn v -> generate_distribution(employee_id, v) end)

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary days.
        vacation_available_to_employee
        |> Enum.take(
          Draft.EmployeeVacationQuota.adjust_quota(
            quota,
            anniversary_weeks
          )
        )
        |> Enum.map(fn v -> generate_distribution(employee_id, v) end)

      :after_range ->
        vacation_available_to_employee
        |> Enum.take(
          Draft.EmployeeVacationQuota.adjust_quota(
            quota,
            anniversary_weeks
          )
        )
        |> Enum.map(fn v -> generate_distribution(employee_id, v) end)
    end
  end

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
      # TODO better handling here -- {:error, errors?}
      [] -> nil
      [balance] -> calculated_quota_from_balance(balance, employee.job_class, :week)
      _multiple_balances -> nil
    end
  end

  defp calculated_quota_from_balance(employee_balance, job_class, :week = interval_type) do
    max_minutes = employee_balance.maximum_minutes

    num_hours_per_day = Draft.JobClassHelpers.num_hours_per_day(job_class)

    # Cap weeks by the maximum number of paid vacation minutes an operator has remaining
    max_weeks = min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

    anniversary_quota = Draft.EmployeeVacationQuota.get_anniversary_quota(employee_balance)

    {max_weeks, anniversary_quota}
  end

  defp available_preferences(
         preferences,
         distributions_in_run_by_date,
         round,
         employee_ranking,
         :week = interval_type
       ) do
    all_available_vacation =
      MapSet.new(
        all_vacation_available_to_employee(
          distributions_in_run_by_date,
          round,
          employee_ranking,
          interval_type
        ),
        fn w -> {w.start_date, w.end_date} end
      )

    Enum.flat_map(preferences, fn p ->
      if MapSet.member?(all_available_vacation, {p.start_date, p.end_date}) do
        [
          %{
            start_date: p.start_date,
            end_date: p.end_date,
            rank: p.rank,
            interval_type: interval_type
          }
        ]
      else
        []
      end
    end)
  end

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
      %{start_date: q.start_date, end_date: q.end_date, interval_type: interval_type, rank: nil}
    end)
  end

  defp generate_distribution(employee_id, dist) do
    Logger.info("assigned #{dist.interval_type} - #{dist.start_date} - #{dist.end_date}")

    %VacationDistribution{
      employee_id: employee_id,
      interval_type: dist.interval_type,
      start_date: dist.start_date,
      end_date: dist.end_date
    }
  end
end

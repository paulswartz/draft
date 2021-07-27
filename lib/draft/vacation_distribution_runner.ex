defmodule Draft.VacationDistributionRunner do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has any weeks left in their vacation balance, they will be assigned available vacation weeks for their division.
  Otherwise, they will be assigned days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationQuota
  alias Draft.GenerateVacationDistribution
  alias Draft.Repo
  alias Draft.VacationDistribution
  alias Draft.VacationQuotaSetup

  require Logger

  @type distribution_result() :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Distribute vacation to all employees in the given group in seniority order.
  """
  def distribute_vacation_to_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
    group =
      Repo.get_by(BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    if group do
      round = Repo.get_by!(BidRound, round_id: round_id, process_id: process_id)
      initial_quota = Draft.DivisionVacationWeekQuota.filled_quota(round)

      case Repo.all(
             from e in EmployeeRanking,
               where:
                 e.round_id == ^group.round_id and e.process_id == ^group.process_id and
                   e.group_number == ^group.group_number,
               order_by: [asc: [e.group_number, e.rank]]
           ) do
        [first_emp, remaining_emps] ->
          distribute_for_group(
            initial_quota,
            %{
              # TODO -- incorporate hours / job class / anniversary into weekly quota
              remaining_quota: first_emp.weekly_quota,
              possible_assignments: generate_from_available(round, first_emp, %{}),
              employee_id: first_emp.employee_id
            },
            remaining_emps,
            %{}
          )

        [first_emp] ->
          distribute_for_group(
            initial_quota,
            %{
              # TODO -- incorporate hours / job class / anniversary into weekly quota
              remaining_quota: first_emp.weekly_quota,
              possible_assignments: generate_from_available(round, first_emp, %{}),
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

  defp generate_from_available(
         round,
         employee,
         assignments
       ) do
    preference_set =
      Draft.EmployeeVacationPreferenceSet.get_latest_preferences(
        employee.process_id,
        employee.round_id,
        employee.employee_id
      )

    all_available_weeks = get_all_weeks_available_to_employee(round, employee, assignments)

    preferred_vacation_weeks =
      if is_nil(preference_set) do
        %{}
      else
        preference_set.vacation_preferences
        |> Enum.filter(fn p -> p.interval_type == :week end)
        |> Enum.into(%{}, fn p -> {p.start_date, p.rank} end)
      end

    all_available_weeks
    |> Enum.map(fn w -> Map.put(w, :rank, Map.get(preferred_vacation_weeks, w.start_date)) end)
    |> Enum.sort_by(&{&1.rank, &1.start_date})
  end

  #
  # TODO - sort by date desc
  # defp compare_ranked_vacation(vacation1, vacation2) =
  # lhs, rhs ->
  # case {compare.(lhs[:age],rhs[:age]), compare.(lhs[:name],rhs[:name])} do
  # {:lt, _} -> false
  # {:eq, :gt} -> false
  # {_,_} -> true
  # end
  # end

  defp get_all_weeks_available_to_employee(
         round,
         employee,
         assignments
       ) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    quota_already_distributed_in_run =
      Enum.into(assignments, %{}, fn {date, emps} -> {date, MapSet.size(emps)} end)

    conflicting_selected_vacation_query =
      from s in Draft.EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_week_quota).end_date and
            s.end_date >= parent_as(:division_week_quota).start_date and
            s.employee_id == ^employee.employee_id

    quotas_before_run =
      Repo.all(
        from w in Draft.DivisionVacationWeekQuota,
          as: :division_week_quota,
          where:
            w.division_id == ^round.division_id and w.quota > 0 and w.is_restricted_week == false and
              w.employee_selection_set == ^selection_set and
              ^round.rating_period_start_date <= w.start_date and
              ^round.rating_period_end_date >= w.end_date and
              not exists(conflicting_selected_vacation_query),
          order_by: [asc: w.start_date]
      )

    quotas_before_run
    |> Enum.map(fn original_quota ->
      %Draft.DivisionVacationWeekQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(quota_already_distributed_in_run, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
  end

  defp distribute_for_group(
         vacation_schedule,
         %{
           remaining_quota: remaining_quota,
           possible_assignments: possible_assignments,
           employee_id: employee_id
         } = current_employee,
         remaining_employees,
         assignments
       ) do
    if is_completed_schedule(vacation_schedule, remaining_employees) do
      {:ok, assignments}
    end

    if is_invalid_schedule(current_employee) do
      {:error, :invalid_schedule}
    end

    # reduce while?
    Enum.map(Enum.with_index(possible_assignments), fn o, index ->
      [_assignments_in_previous_branch, remaining_assignments] =
        Enum.split(possible_assignments, index)

      distribute_for_group(
        Map.update!(vacation_schedule, o.start_date, fn {rem_quota, emps} ->
          {rem_quota - 1, MapSet.put(emps, employee_id)}
        end),
        %{
          employee_id: employee_id,
          remaining_quota: remaining_quota - 1,
          possible_assignments: remaining_assignments
        },
        remaining_employees,
        Map.update(assignments, current_employee.employee_id, MapSet.new([o.start_date]), fn v ->
          MapSet.put(v, o.start_date)
        end)
      )
    end)
  end

  defp is_invalid_schedule(current_emp) do
    current_emp.remaining_quota > 0 and MapSet.size(current_emp.possible_assignments) == 0
    ## TODO: Add other checks?
  end

  defp is_completed_schedule(_quota, employees) do
    employees == []
    ## TODO: Add checks to make sure quota is as expected?
  end
end

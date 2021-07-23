defmodule Draft.GenerateVacationDistribution.Weeks do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to the given employee
  """
  import Ecto.Query
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  alias Draft.VacationDistribution
  require Logger

  @spec generate(
          integer(),
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          integer(),
          nil | %{anniversary_date: Date.t(), anniversary_weeks: number()}
        ) :: [VacationDistribution.t()]

  @doc """
  generate a list of vacation weeks for an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation weeks are only generated up to that date.
  """
  def generate(
        distribution_run_id,
        round,
        employee,
        max_weeks,
        anniversary_vacation
      )

  def generate(distribution_run_id, round, employee, max_weeks, nil) do
    generate_from_available(
      distribution_run_id,
      round,
      employee,
      max_weeks
    )
  end

  def generate(distribution_run_id, round, employee, week_quota_including_anniversary_weeks, %{
        anniversary_date: anniversary_date,
        anniversary_weeks: anniversary_weeks
      }) do
    case Draft.Utils.compare_date_to_range(
           anniversary_date,
           round.rating_period_start_date,
           round.rating_period_end_date
         ) do
      :before_range ->
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          week_quota_including_anniversary_weeks
        )

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary weeks.
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            week_quota_including_anniversary_weeks,
            anniversary_weeks
          )
        )

      :after_range ->
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            week_quota_including_anniversary_weeks,
            anniversary_weeks
          )
        )
    end
  end

  defp generate_from_available(
         distribution_run_id,
         round,
         employee,
         max_weeks
       ) do
    preference_set =
      Draft.EmployeeVacationPreferenceSet.get_latest_preferences(
        employee.process_id,
        employee.round_id,
        employee.employee_id
      )

    all_available_weeks =
      get_all_weeks_available_to_employee(distribution_run_id, round, employee)

    preferred_vacation_weeks =
      if is_nil(preference_set) do
        []
      else
        Enum.filter(preference_set.vacation_preferences, fn p -> p.interval_type == :week end)
      end

    generate_weeks_to_distribute_from_preferences(
      employee,
      all_available_weeks,
      preferred_vacation_weeks,
      max_weeks
    )
  end

  defp generate_weeks_to_distribute_from_preferences(
         employee,
         all_available_weeks,
         preferred_weeks,
         max_weeks
       )

  defp generate_weeks_to_distribute_from_preferences(employee, all_available_weeks, [], max_weeks) do
    generate_weeks(employee, Enum.take(all_available_weeks, max_weeks))
  end

  defp generate_weeks_to_distribute_from_preferences(
         employee,
         all_available_weeks,
         preferred_weeks,
         max_weeks
       ) do
    available_weeks_set = MapSet.new(all_available_weeks, fn w -> {w.start_date, w.end_date} end)

    available_preferred_weeks =
      preferred_weeks
      |> Enum.filter(fn preferred_week ->
        MapSet.member?(available_weeks_set, {preferred_week.start_date, preferred_week.end_date})
      end)
      |> Enum.take(max_weeks)

    generate_weeks(employee, available_preferred_weeks)
  end

  defp get_all_weeks_available_to_employee(
         distribution_run_id,
         round,
         employee
       ) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :week)

    conflicting_selected_vacation_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_week_quota).end_date and
            s.end_date >= parent_as(:division_week_quota).start_date and
            s.employee_id == ^employee.employee_id and
            s.status == :assigned

    quotas_before_run =
      Repo.all(
        from w in DivisionVacationWeekQuota,
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
      %DivisionVacationWeekQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(quota_already_distributed_in_run, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
  end

  defp generate_weeks(employee, available_weeks)

  defp generate_weeks(_employee, []) do
    Logger.info("No more vacation weeks available")
    []
  end

  defp generate_weeks(employee, available_weeks) do
    Enum.map(available_weeks, &generate_week(employee, &1))
  end

  defp generate_week(employee, assigned_week) do
    Logger.info("assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}")

    %VacationDistribution{
      employee_id: employee.employee_id,
      interval_type: :week,
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date
    }
  end
end

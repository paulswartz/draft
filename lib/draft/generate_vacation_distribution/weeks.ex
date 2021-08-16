defmodule Draft.GenerateVacationDistribution.Weeks do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to the given employee
  """
  @behaviour Draft.GenerateVacationDistribution.Voluntary
  alias Draft.DivisionVacationWeekQuota
  alias Draft.GenerateVacationDistribution.Voluntary
  alias Draft.VacationDistribution

  require Logger

  @doc """
  generate a list of vacation weeks for an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation weeks are only generated up to that date.
  """
  @impl Voluntary
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
      Draft.EmployeeVacationPreferenceSet.latest_preference_set(
        employee.process_id,
        employee.round_id,
        employee.employee_id,
        [:week]
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
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :week)

    round
    |> DivisionVacationWeekQuota.available_quota(employee)
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

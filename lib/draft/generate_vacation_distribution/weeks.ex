defmodule Draft.GenerateVacationDistribution.Weeks do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to the given employee
  based on their preferences
  """
  @behaviour Draft.GenerateVacationDistribution.Voluntary
  alias Draft.GenerateVacationDistribution.Voluntary
  alias Draft.VacationDistribution
  require Logger

  @doc """
  generate a list of vacation weeks for an employee based on their preferences and what is
  still available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, distributions will be generated only
  for the amount of quota earned prior to the anniversary.
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
    distribution_run_id
    |> preferred_available_weeks(round, employee)
    |> Enum.take(max_weeks)
    |> Enum.map(&to_distribution(&1, employee))
  end

  defp preferred_available_weeks(
         distribution_run_id,
         round,
         employee
       ) do
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :week)

    round
    |> Draft.DivisionQuotaRanked.available_to_employee(employee, :week)
    |> Enum.map(fn original_quota ->
      %{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(quota_already_distributed_in_run, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
    |> Enum.filter(& &1.preference_rank)
  end

  defp to_distribution(assigned_week, employee) do
    Logger.info("assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}")

    %VacationDistribution{
      employee_id: employee.employee_id,
      interval_type: :week,
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date,
      preference_rank: assigned_week.preference_rank,
      is_forced: false
    }
  end
end

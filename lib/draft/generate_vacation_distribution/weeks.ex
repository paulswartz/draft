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
        session,
        employee_vacation_quota_summary
      ) do
    max_weeks =
      employee_vacation_quota_summary
      |> Draft.EmployeeVacationQuotaSummary.minutes_available_as_of_date(
        session.rating_period_start_date
      )
      |> div(
        Draft.JobClassHelpers.num_hours_per_week(employee_vacation_quota_summary.job_class) * 60
      )

    distribution_run_id
    |> preferred_available_weeks(session, employee_vacation_quota_summary)
    |> Enum.take(max_weeks)
    |> Enum.map(&to_distribution(&1, employee_vacation_quota_summary.employee_id))
  end

  defp preferred_available_weeks(
         distribution_run_id,
         session,
         employee_vacation_quota_summary
       ) do
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :week)

    session
    |> Draft.DivisionQuota.available_with_employee_rank(employee_vacation_quota_summary)
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

  defp to_distribution(assigned_week, employee_id) do
    Logger.info("assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}")

    %VacationDistribution{
      employee_id: employee_id,
      interval_type: :week,
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date,
      preference_rank: assigned_week.preference_rank,
      is_forced: false
    }
  end
end

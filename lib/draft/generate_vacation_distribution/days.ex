defmodule Draft.GenerateVacationDistribution.Days do
  @moduledoc """
  Generate a list of VacationDistributions that can be assigned to the given employee
  """
  @behaviour Draft.GenerateVacationDistribution.Voluntary
  alias Draft.GenerateVacationDistribution.Voluntary
  alias Draft.VacationDistribution
  require Logger

  @doc """
  Generate vacation days to assign for the employee based on what is available in their
  division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, distributions will be generated only
  for the amount of quota earned prior to the anniversary.
  """
  @impl Voluntary
  def generate(
        distribution_run_id,
        session,
        employee_vacation_quota_summary
      ) do
    # Assumes 5/2 work schedule for now
    max_days =
      employee_vacation_quota_summary
      |> Draft.EmployeeVacationQuotaSummary.minutes_available_as_of_date(
        session.rating_period_start_date
      )
      |> div(
        Draft.JobClassHelpers.num_hours_per_day(
          employee_vacation_quota_summary.job_class,
          :five_two
        ) * 60
      )

    distribution_run_id
    |> preferred_available_days(session, employee_vacation_quota_summary.employee_id)
    |> Enum.take(max_days)
    |> Enum.map(&to_distribution(&1, employee_vacation_quota_summary.employee_id))
  end

  defp preferred_available_days(
         distribution_run_id,
         session,
         employee_id
       ) do
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :day)

    Draft.DivisionQuota.only_ranked_available_quota(
      session,
      employee_id,
      quota_already_distributed_in_run
    )
  end

  defp to_distribution(assigned_day, employee_id) do
    Logger.info("assigned day - #{assigned_day.start_date}")

    %VacationDistribution{
      employee_id: employee_id,
      interval_type: :day,
      start_date: assigned_day.start_date,
      end_date: assigned_day.end_date,
      preference_rank: assigned_day.preference_rank,
      is_forced: false
    }
  end
end

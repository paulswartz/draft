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
        round,
        employee,
        max_days,
        anniversary_vacation
      )

  def generate(distribution_run_id, round, employee, max_days, nil) do
    generate_from_available(
      distribution_run_id,
      round,
      employee,
      max_days
    )
  end

  def generate(
        distribution_run_id,
        round,
        employee,
        day_quota_including_anniversary_days,
        %{
          anniversary_date: anniversary_date,
          anniversary_days: anniversary_days
        }
      ) do
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
          day_quota_including_anniversary_days
        )

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary days.
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          )
        )

      :after_range ->
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          )
        )
    end
  end

  defp generate_from_available(
         distribution_run_id,
         round,
         employee,
         max_days
       )

  defp generate_from_available(
         distribution_run_id,
         round,
         employee,
         max_days
       ) do
    preferred_days =
      distribution_run_id
      |> preferred_available_days(round, employee)
      |> Enum.take(max_days)

    Enum.map(preferred_days, &to_distribution(employee, &1))
  end

  defp preferred_available_days(
         distribution_run_id,
         round,
         employee
       ) do
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :day)

    round
    |> Draft.DivisionQuotaRanked.available_to_employee(employee, :day)
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

  defp to_distribution(employee, assigned_day) do
    Logger.info("assigned day - #{assigned_day.start_date}")

    %VacationDistribution{
      employee_id: employee.employee_id,
      interval_type: :day,
      start_date: assigned_day.start_date,
      end_date: assigned_day.end_date,
      preference_rank: assigned_day.preference_rank,
      is_forced: false
    }
  end
end

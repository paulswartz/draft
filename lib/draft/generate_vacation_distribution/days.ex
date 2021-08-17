defmodule Draft.GenerateVacationDistribution.Days do
  @moduledoc """
  Generate a list of VacationDistributions that can be assigned to the given employee
  """
  @behaviour Draft.GenerateVacationDistribution.Voluntary
  alias Draft.DivisionVacationDayQuota
  alias Draft.GenerateVacationDistribution.Voluntary
  alias Draft.VacationDistribution
  require Logger

  @doc """
  Generate vacation days to assign for the employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation days are only generated up to that date.
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
         _distribution_run_id,
         _round,
         _employee,
         0
       ) do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this rating period."
    )

    []
  end

  defp generate_from_available(
         distribution_run_id,
         round,
         employee,
         max_days
       ) do
    preference_set =
      Draft.EmployeeVacationPreferenceSet.get_latest_preferences(
        employee.process_id,
        employee.round_id,
        employee.employee_id
      )

    all_available_days = get_all_days_available_to_employee(distribution_run_id, round, employee)

    preferred_vacation_days =
      if is_nil(preference_set) do
        []
      else
        Enum.filter(preference_set.vacation_preferences, fn p -> p.interval_type == :day end)
      end

    generate_days_to_distribute_from_preferences(
      employee,
      all_available_days,
      preferred_vacation_days,
      max_days
    )
  end

  defp get_all_days_available_to_employee(distribution_run_id, round, employee) do
    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_unsynced_assignments_by_date(distribution_run_id, :day)

    round
    |> DivisionVacationDayQuota.available_quota(employee)
    |> Enum.map(fn original_quota ->
      %DivisionVacationDayQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(quota_already_distributed_in_run, original_quota.date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
  end

  defp generate_days_to_distribute_from_preferences(
         employee,
         all_available_days,
         preferred_days,
         max_days
       )

  defp generate_days_to_distribute_from_preferences(employee, all_available_days, [], max_days) do
    generate_days(employee, Enum.take(all_available_days, max_days))
  end

  defp generate_days_to_distribute_from_preferences(
         employee,
         all_available_days,
         preferred_days,
         max_days
       ) do
    available_days_set = MapSet.new(all_available_days, fn d -> d.date end)

    available_preferred_days =
      preferred_days
      |> Enum.filter(fn preferred_day ->
        MapSet.member?(available_days_set, preferred_day.start_date)
      end)
      |> Enum.take(max_days)
      |> Enum.map(fn d -> %{date: d.start_date} end)

    generate_days(employee, available_preferred_days)
  end

  defp generate_days(employee, available_days)

  defp generate_days(_employee, []) do
    Logger.info("No more vacation days available")
    []
  end

  defp generate_days(employee, available_days) do
    Enum.map(available_days, &generate_day(employee, &1))
  end

  defp generate_day(employee, selected_day) do
    Logger.info("assigned day - #{selected_day.date}")

    %VacationDistribution{
      employee_id: employee.employee_id,
      interval_type: :day,
      start_date: selected_day.date,
      end_date: selected_day.date
    }
  end
end

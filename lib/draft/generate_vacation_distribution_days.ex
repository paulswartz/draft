defmodule Draft.GenerateVacationDistribution.Days do
  @moduledoc """
  Generate a list of VacationDistributions that can be assigned to the given employee
  """
  import Ecto.Query
  alias Draft.DivisionVacationDayQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  alias Draft.VacationDistribution
  require Logger

  @spec generate(
          integer(),
          Draft.BidRound,
          Draft.EmployeeRanking,
          integer(),
          [VacationDistribution],
          nil | %{anniversary_date: Date.t(), anniversary_days: number()}
        ) :: [VacationDistribution]

  @doc """
  Generate vacation days to assign for the employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation days are only generated up to that date.
  """
  def generate(
        distribution_run_id,
        round,
        employee,
        max_days,
        assigned_weeks,
        anniversary_vacation
      )

  def generate(distribution_run_id, round, employee, max_days, assigned_weeks, nil) do
    generate_from_available(
      distribution_run_id,
      round,
      employee,
      max_days,
      assigned_weeks
    )
  end

  def generate(
        distribution_run_id,
        round,
        employee,
        day_quota_including_anniversary_days,
        assigned_weeks,
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
          day_quota_including_anniversary_days,
          assigned_weeks
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
          ),
          assigned_weeks
        )

      :after_range ->
        generate_from_available(
          distribution_run_id,
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          ),
          assigned_weeks
        )
    end
  end

  defp generate_from_available(
         distribution_run_id,
         round,
         employee,
         max_days,
         assigned_weeks
       )

  defp generate_from_available(
         distribution_run_id,
         _round,
         _employee,
         0,
         _assigned_weeks
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
         max_days,
         [] = _assigned_weeks
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

  defp generate_from_available(
         _distribution_run_id,
         _round,
         _employee,
         _max_days,
         _assigned_weeks
       ) do
    Logger.info(
      "Skipping vacation day assignment -- only assigning weeks or days for now, and weeks have already been assigned."
    )

    []
  end

  defp get_all_days_available_to_employee(distribution_run_id, round, employee) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    quota_already_distributed_in_run =
      Draft.VacationDistribution.count_distributions_per_interval(distribution_run_id, :day)

    conflicting_selected_dates_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_day_quota).date and
            s.end_date >= parent_as(:division_day_quota).date and
            s.employee_id == ^employee.employee_id

    quotas_before_run =
      Repo.all(
        from d in DivisionVacationDayQuota,
          as: :division_day_quota,
          where:
            d.division_id == ^round.division_id and d.quota > 0 and
              d.employee_selection_set == ^selection_set and
              d.date >= ^round.rating_period_start_date and
              d.date <= ^round.rating_period_end_date and
              not exists(conflicting_selected_dates_query),
          order_by: [asc: d.date]
      )

    Enum.map(quotas_before_run, fn original_quota ->
      %DivisionVacationDayQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(quota_already_distributed_in_run, original_quota.date, 0)
      }
    end)
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
    available_preferred_days =
      all_available_days
      |> Enum.filter(fn a ->
        Enum.any?(preferred_days, fn p ->
          p.start_date == a.date
        end)
      end)
      |> Enum.take(max_days)

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

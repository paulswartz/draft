defmodule Draft.VacationDistribution.Day do
  @moduledoc """
  Distribute vacation days to an employee.
  """
  import Ecto.Query
  alias Draft.DivisionVacationDayQuota
  alias Draft.EmployeeVacationAssignment
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  require Logger

  @spec distribute(
          Draft.BidRound,
          Draft.EmployeeRanking,
          integer(),
          [EmployeeVacationAssignment],
          nil | %{anniversary_date: Date.t(), anniversary_days: number()}
        ) :: [EmployeeVacationAssignment]

  @doc """
  Distribute vacation days to an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation days are only assigned up to that date.
  """
  def distribute(
        round,
        employee,
        max_days,
        assigned_weeks,
        anniversary_vacation
      )

  def distribute(round, employee, max_days, assigned_weeks, nil) do
    distribute_from_available(
      round,
      employee,
      max_days,
      assigned_weeks
    )
  end

  def distribute(_round, _employee, 0, _assigned_weeks, _anniversary_vacation) do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this range."
    )

    []
  end

  def distribute(
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
        distribute_from_available(
          round,
          employee,
          day_quota_including_anniversary_days,
          assigned_weeks
        )

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary days.
        distribute_from_available(
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          ),
          assigned_weeks
        )

      :after_range ->
        distribute_from_available(
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

  defp distribute_from_available(
         round,
         employee,
         max_days,
         assigned_weeks
       )

  defp distribute_from_available(
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

  defp distribute_from_available(
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

    all_available_days = get_all_days_available_to_employee(round, employee)

    preferred_vacation_days =
      if is_nil(preference_set) do
        []
      else
        Enum.filter(preference_set.vacation_preferences, fn p -> p.interval_type == "day" end)
      end

    distribute_available_days_from_preferences(
      employee,
      all_available_days,
      preferred_vacation_days,
      max_days
    )
  end

  defp distribute_from_available(
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

  defp get_all_days_available_to_employee(round, employee) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    conflicting_selected_dates_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_day_quota).date and
            s.end_date >= parent_as(:division_day_quota).date and
            s.employee_id == ^employee.employee_id

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
  end

  defp distribute_available_days_from_preferences(
         employee,
         all_available_days,
         preferred_days,
         max_days
       )

  defp distribute_available_days_from_preferences(employee, all_available_days, [], max_days) do
    distribute_days(employee, Enum.take(all_available_days, max_days))
  end

  defp distribute_available_days_from_preferences(
         employee,
         all_available_days,
         preferred_days,
         max_days
       ) do
    available_preferred_days =
      all_available_days
      |> Enum.filter(fn d ->
        Enum.any?(preferred_days, fn p ->
          p.start_date == d.date
        end)
      end)
      |> Enum.take(max_days)

    distribute_days(employee, available_preferred_days)
  end

  defp distribute_days(employee, available_days)

  defp distribute_days(_employee, []) do
    Logger.info("No more vacation days available")
    []
  end

  defp distribute_days(employee, available_days) do
    Enum.each(available_days, fn date_quota ->
      Repo.update(DivisionVacationDayQuota.changeset(date_quota, %{quota: date_quota.quota - 1}))
    end)

    Enum.map(available_days, &distribute_day(employee, &1))
  end

  defp distribute_day(employee, selected_day) do
    Logger.info("assigned day - #{selected_day.date}")

    %EmployeeVacationAssignment{
      employee_id: employee.employee_id,
      is_week?: false,
      start_date: selected_day.date,
      end_date: selected_day.date
    }
  end
end

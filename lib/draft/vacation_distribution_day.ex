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
    distribute_in_range(
      round.division_id,
      employee,
      max_days,
      assigned_weeks,
      round.rating_period_start_date,
      round.rating_period_end_date
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
        distribute_in_range(
          round.division_id,
          employee,
          day_quota_including_anniversary_days,
          assigned_weeks,
          round.rating_period_start_date,
          round.rating_period_end_date
        )

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary days.
        distribute_in_range(
          round.division_id,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          ),
          assigned_weeks,
          round.rating_period_start_date,
          round.rating_period_end_date
        )

      :after_range ->
        distribute_in_range(
          round.division_id,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            day_quota_including_anniversary_days,
            anniversary_days
          ),
          assigned_weeks,
          round.rating_period_start_date,
          round.rating_period_end_date
        )
    end
  end

  defp distribute_in_range(
         division_id,
         employee,
         max_days,
         assigned_weeks,
         range_start_date,
         range_end_Date
       )

  defp distribute_in_range(
         _division_id,
         _employee,
         0,
         _assigned_weeks,
         _range_start_date,
         _range_end_date
       ) do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this rating period."
    )

    []
  end

  defp distribute_in_range(
         division_id,
         employee,
         max_days,
         [] = _assigned_weeks,
         range_start_date,
         range_end_date
       ) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    conflicting_selected_dates_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_day_quota).date and
            s.end_date >= parent_as(:division_day_quota).date and
            s.employee_id == ^employee.employee_id

    first_available_days =
      Repo.all(
        from d in DivisionVacationDayQuota,
          as: :division_day_quota,
          where:
            d.division_id == ^division_id and d.quota > 0 and
              d.employee_selection_set == ^selection_set and
              d.date >= ^range_start_date and
              d.date <= ^range_end_date and
              not exists(conflicting_selected_dates_query),
          order_by: [asc: d.date],
          limit: ^max_days
      )

    distribute_days(employee, first_available_days)
  end

  defp distribute_in_range(
         _division_id,
         _employee,
         _max_days,
         _assigned_weeks,
         _range_start_date,
         _range_end_date
       ) do
    Logger.info(
      "Skipping vacation day assignment -- only assigning weeks or days for now, and weeks have already been assigned."
    )

    []
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

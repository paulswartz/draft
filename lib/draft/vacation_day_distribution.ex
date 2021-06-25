defmodule Draft.VacationDayDistribution do
  @moduledoc """
  Distribute vacation days to an employee.
  """
  import Ecto.Query
  alias Draft.DivisionVacationDayQuota
  alias Draft.EmployeeVacationAssignment
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  require Logger

  @spec distribute_days_balance(
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
  def distribute_days_balance(
        round,
        employee,
        max_days,
        assigned_weeks,
        anniversary_vacation
      )

  def distribute_days_balance(round, employee, max_days, assigned_weeks, nil) do
    distribute_days_balance_in_range(
      round.division_id,
      employee,
      max_days,
      assigned_weeks,
      round.rating_period_start_date,
      round.rating_period_end_date
    )
  end

  def distribute_days_balance(_round, _employee, 0, _assigned_weeks, _anniversary_vacation) do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this range."
    )

    []
  end

  def distribute_days_balance(
        round,
        employee,
        day_quota_including_anniversary_days,
        assigned_weeks,
        %{
          anniversary_date: anniversary_date,
          anniversary_days: anniversary_days
        }
      ) do
    case Date.compare(anniversary_date, round.rating_period_start_date) do
      :gt ->
        # anniversary has not yet passed. distribute only earned day quota until anniversary date.
        range_end_date =
          if Date.compare(anniversary_date, round.rating_period_end_date) == :lt do
            Date.add(anniversary_date, -1)
          else
            round.rating_period_end_date
          end

        distribute_days_balance_in_range(
          round.division_id,
          employee,
          max(day_quota_including_anniversary_days - anniversary_days, 0),
          assigned_weeks,
          round.rating_period_start_date,
          range_end_date
        )

      # could potentially assign any remaining unused day balance + anniversary day here

      _lt_or_eq ->
        # anniversary has passed - can distribute full day quota
        distribute_days_balance_in_range(
          round.division_id,
          employee,
          day_quota_including_anniversary_days,
          assigned_weeks,
          round.rating_period_start_date,
          round.rating_period_end_date
        )
    end
  end

  defp distribute_days_balance_in_range(
         division_id,
         employee,
         max_days,
         assigned_weeks,
         range_start_date,
         range_end_Date
       )

  defp distribute_days_balance_in_range(
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

  defp distribute_days_balance_in_range(
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

    distribute_available_days_balance(employee, first_available_days)
  end

  defp distribute_days_balance_in_range(
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

  defp distribute_available_days_balance(employee, available_days)

  defp distribute_available_days_balance(_employee, []) do
    Logger.info("No more vacation days available")
    []
  end

  defp distribute_available_days_balance(employee, available_days) do
    Enum.each(available_days, fn date_quota ->
      Repo.update(DivisionVacationDayQuota.changeset(date_quota, %{quota: date_quota.quota - 1}))
    end)

    Enum.map(available_days, &distribute_single_day(employee, &1))
  end

  defp distribute_single_day(employee, selected_day) do
    Logger.info("assigned day - #{selected_day.date}")

    %EmployeeVacationAssignment{
      employee_id: employee.employee_id,
      is_week?: false,
      start_date: selected_day.date,
      end_date: selected_day.date
    }
  end
end

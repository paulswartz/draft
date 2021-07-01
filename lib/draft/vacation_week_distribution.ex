defmodule Draft.VacationWeekDistribution do
  @moduledoc """
  Distribute vacation weeks to an employee.
  """
  import Ecto.Query
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  require Logger

  @spec distribute_weeks_balance(
          Draft.BidRound,
          Draft.EmployeeRanking,
          integer(),
          nil | %{anniversary_date: Date.t(), anniversary_weeks: number()}
        ) :: [EmployeeVacationSelection]

  @doc """
  Distribute vacation weeks to an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation weeks are only assigned up to that date.
  """
  def distribute_weeks_balance(
        round,
        employee,
        max_weeks,
        anniversary_vacation
      )

  def distribute_weeks_balance(round, employee, max_weeks, nil) do
    distribute_weeks_balance_in_range(
      round.division_id,
      employee,
      max_weeks,
      round.rating_period_start_date,
      round.rating_period_end_date
    )
  end

  def distribute_weeks_balance(_round, _employee, 0, _anniversary_vacation) do
    Logger.info(
      "Skipping vacation week assignment - employee cannot take any weeks off in this range."
    )

    []
  end

  def distribute_weeks_balance(round, employee, week_quota_including_anniversary_weeks, %{
        anniversary_date: anniversary_date,
        anniversary_weeks: anniversary_weeks
      }) do
    case Date.compare(anniversary_date, round.rating_period_start_date) do
      :gt ->
        distribute_weeks_balance_in_range(
          round.division_id,
          employee,
          max(week_quota_including_anniversary_weeks - anniversary_weeks, 0),
          round.rating_period_start_date,
          round.rating_period_end_date
        )

      # could also assign anniversary week here if anniversary falls in rating period

      _lt_or_eq ->
        # anniversary has passed - can distribute full week quota
        distribute_weeks_balance_in_range(
          round.division_id,
          employee,
          week_quota_including_anniversary_weeks,
          round.rating_period_start_date,
          round.rating_period_end_date
        )
    end
  end

  defp distribute_weeks_balance_in_range(
         division_id,
         employee,
         max_weeks,
         range_start_date,
         range_end_date
       ) do
    preference_set =
      Draft.EmployeeVacationPreferenceSet.get_latest_preferences(
        employee.process_id,
        employee.round_id,
        employee.employee_id
      )

    all_available_weeks =
      get_all_weeks_available_to_employee(division_id, employee, range_start_date, range_end_date)

    preferred_vacation_weeks =
      if is_nil(preference_set) do
        []
      else
        Enum.filter(preference_set.vacation_preferences, fn p -> p.interval_type == "week" end)
      end

    distribute_available_weeks_from_preferences(
      employee,
      all_available_weeks,
      preferred_vacation_weeks,
      max_weeks
    )
  end

  defp distribute_available_weeks_from_preferences(
         employee,
         all_available_weeks,
         preferred_weeks,
         max_weeks
       )

  defp distribute_available_weeks_from_preferences(employee, all_available_weeks, [], max_weeks) do
    distribute_weeks(employee, Enum.take(all_available_weeks, max_weeks))
  end

  defp distribute_available_weeks_from_preferences(
         employee,
         all_available_weeks,
         preferred_weeks,
         max_weeks
       ) do
    available_preferred_weeks =
      all_available_weeks
      |> Enum.filter(fn w ->
        Enum.any?(preferred_weeks, fn p ->
          p.start_date == w.start_date && p.end_date == w.end_date
        end)
      end)
      |> Enum.take(max_weeks)

    distribute_weeks(employee, available_preferred_weeks)
  end

  defp get_all_weeks_available_to_employee(
         division_id,
         employee,
         range_start_date,
         range_end_date
       ) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    conflicting_selected_vacation_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_week_quota).end_date and
            s.end_date >= parent_as(:division_week_quota).start_date and
            s.employee_id == ^employee.employee_id

    Repo.all(
      from w in DivisionVacationWeekQuota,
        as: :division_week_quota,
        where:
          w.division_id == ^division_id and w.quota > 0 and w.is_restricted_week == false and
            w.employee_selection_set == ^selection_set and
            ^range_start_date <= w.start_date and
            ^range_end_date >= w.end_date and
            not exists(conflicting_selected_vacation_query),
        order_by: [asc: w.start_date]
    )
  end

  defp distribute_weeks(employee, available_weeks)

  defp distribute_weeks(_employee, []) do
    Logger.info("No more vacation weeks available")
    []
  end

  defp distribute_weeks(employee, available_weeks) do
    Enum.map(available_weeks, &distribute_week(employee, &1))
  end

  defp distribute_week(employee, assigned_week) do
    new_quota = assigned_week.quota - 1
    changeset = DivisionVacationWeekQuota.changeset(assigned_week, %{quota: new_quota})
    Repo.update(changeset)

    Logger.info(
      "assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}. #{new_quota} more openings for this week.\n"
    )

    %EmployeeVacationSelection{
      employee_id: employee.employee_id,
      vacation_interval_type: "week",
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date
    }
  end
end

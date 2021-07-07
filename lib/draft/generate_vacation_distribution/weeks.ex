defmodule Draft.GenerateVacationDistribution.Weeks do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to the given employee
  """
  import Ecto.Query
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  alias Draft.VacationDistribution
  require Logger

  @spec generate(
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          integer(),
          nil | %{anniversary_date: Date.t(), anniversary_weeks: number()}
        ) :: [VacationDistribution.t()]

  @doc """
  generate a list of vacation weeks for an employee based on what is available in their division/job class in the rating period they are picking for.
  If the employee has an upcoming anniversary date, vacation weeks are only generated up to that date.
  """
  def generate(
        round,
        employee,
        max_weeks,
        anniversary_vacation
      )

  def generate(round, employee, max_weeks, nil) do
    generate_from_available(
      round,
      employee,
      max_weeks
    )
  end

  def generate(round, employee, week_quota_including_anniversary_weeks, %{
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
          round,
          employee,
          week_quota_including_anniversary_weeks
        )

      :in_range ->
        # If it should be possible to assign an operator their anniversary vacation that is earned
        # within a rating period, update case to do so. Currently does not assign any anniversary weeks.
        generate_from_available(
          round,
          employee,
          Draft.EmployeeVacationQuota.adjust_quota(
            week_quota_including_anniversary_weeks,
            anniversary_weeks
          )
        )

      :after_range ->
        generate_from_available(
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
         round,
         employee,
         max_weeks
       ) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    conflicting_selected_vacation_query =
      from s in EmployeeVacationSelection,
        where:
          s.start_date <= parent_as(:division_week_quota).end_date and
            s.end_date >= parent_as(:division_week_quota).start_date and
            s.employee_id == ^employee.employee_id

    available_weeks =
      Repo.all(
        from w in DivisionVacationWeekQuota,
          as: :division_week_quota,
          where:
            w.division_id == ^round.division_id and w.quota > 0 and w.is_restricted_week == false and
              w.employee_selection_set == ^selection_set and
              ^round.rating_period_start_date <= w.start_date and
              ^round.rating_period_end_date >= w.end_date and
              not exists(conflicting_selected_vacation_query),
          order_by: [asc: w.start_date],
          limit: ^max_weeks
      )

    generate_weeks(employee, available_weeks)
  end

  defp generate_weeks(employee, available_weeks)

  defp generate_weeks(_employee, []) do
    Logger.info("No more vacation weeks available")
    []
  end

  defp generate_weeks(employee, available_weeks) do
    Enum.map(available_weeks, &generate_week(employee, &1))
  end

  defp generate_week(employee, assigned_week) do
    new_quota = assigned_week.quota - 1
    changeset = DivisionVacationWeekQuota.changeset(assigned_week, %{quota: new_quota})
    Repo.update(changeset)

    Logger.info(
      "assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}. #{new_quota} more openings for this week.\n"
    )

    %VacationDistribution{
      employee_id: employee.employee_id,
      interval_type: :week,
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date
    }
  end
end

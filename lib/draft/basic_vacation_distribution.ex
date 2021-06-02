defmodule Draft.BasicVacationDistribution do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has at least a week in their vacation balance, they will be assigned the soonest week available for their division.
  Otherwise, they will be assigned the soonest vacation days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.DivisionVacationDayQuota
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationQuota
  alias Draft.Repo

  require Logger


  @spec basic_vacation_distribution :: :ok
  def basic_vacation_distribution do

    output_file_path = "data/" <> DateTime.to_string(DateTime.utc_now()) <> "test_output.csv"

    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])
    {:ok, output_file} = File.open(output_file_path, [:write])
    Enum.each(bid_rounds, &assign_vacation_for_round(&1, output_file_path))
    File.close(output_file)
  end

  defp assign_vacation_for_round(round, output_file) do
    Logger.info(
      "===================================================================================================\nSTARTING NEW ROUND: #{
        round.rank
      } - #{round.division_id} - #{round.division_description}(#{round.round_id}) (picking between #{
        round.round_opening_date
      } and #{round.round_closing_date} for the rating period #{round.rating_period_start_date} - #{
        round.rating_period_end_date
      })\n"
    )

    selection_set =
      if String.ends_with?(round.round_id, "_PT"), do: "PTVacQuota", else: "FTVacQuota"

    div_dated_quota =
      Repo.all(
        from q in DivisionVacationDayQuota,
          where:
            q.division_id == ^round.division_id and q.employee_selection_set == ^selection_set and
              q.date >= ^round.rating_period_start_date and
              q.date <= ^round.rating_period_end_date
      )

    div_weekly_quota =
      Repo.all(
        from q in DivisionVacationWeekQuota,
          where:
            q.division_id == ^round.division_id and q.employee_selection_set == ^selection_set and
              q.end_date <= ^round.rating_period_end_date and
              q.start_date >= ^round.rating_period_start_date
      )

    bid_groups =
      Repo.all(
        from g in BidGroup,
          where: g.round_id == ^round.round_id and g.process_id == ^round.process_id,
          order_by: [asc: g.group_number]
      )

    Logger.info(
      "Initial division quota: #{length(div_dated_quota)} days, #{length(div_weekly_quota)} weeks "
    )

    {ending_div_dated_quota, ending_div_week_quota} =
      Enum.reduce(bid_groups, {div_dated_quota, div_weekly_quota}, fn group,
                                                                      {dated_quota, weekly_quota} ->
        assign_vacation_for_group(group, round, dated_quota, weekly_quota, output_file)
      end)

    Logger.info(
      "\nEnding division quota: #{length(ending_div_dated_quota)} days, #{
        length(ending_div_week_quota)
      } weeks"
    )
  end

  defp assign_vacation_for_group(group, round, div_dated_quota, div_weekly_quota, output_file) do
    Logger.info(
      "-------------------------------------------------------------------------------------------------\nSTARTING NEW GROUP: #{
        group.group_number
      } (cutoff time #{group.cutoff_datetime})\n"
    )

    group_employees =
      Repo.all(
        from e in EmployeeRanking,
          where:
            e.round_id == ^group.round_id and e.process_id == ^group.process_id and
              e.group_number == ^group.group_number,
          order_by: [asc: e.rank]
      )

    Enum.reduce(group_employees, {div_dated_quota, div_weekly_quota}, fn employee,
                                                                         {dated_quota,
                                                                          weekly_quota} ->
      assign_vacation_for_employee(
        employee,
        round,
        dated_quota,
        weekly_quota,
        output_file
      )
    end)
  end

  defp assign_vacation_for_employee(
         employee,
         round,
         div_dated_quota,
         div_weekly_quota,
         output_file
       ) do
    Logger.info("-------")
    Logger.info("Distributing vacation for employee #{employee.rank}")

    # For now, only getting balance if the balance interval covers the entire rating period.
    employee_balances =
      Repo.all(
        from q in EmployeeVacationQuota,
          where:
            q.employee_id == ^employee.employee_id and
              (q.interval_start_date <= ^round.rating_period_start_date and
                 q.interval_end_date >= ^round.rating_period_end_date)
      )

    if length(employee_balances) == 1 do
      employee_balance = List.first(employee_balances)

      Logger.info(
        "Employee balance for period #{employee_balance.interval_start_date} - #{
          employee_balance.interval_end_date
        }: #{employee_balance.weekly_quota} max weeks, #{employee_balance.dated_quota} max days, #{
          employee_balance.maximum_minutes
        } max minutes"
      )

      max_minutes = employee_balance.maximum_minutes

      max_weeks = min(div(max_minutes, 2400), employee_balance.weekly_quota)

      if max_weeks > 0 && !Enum.empty?(div_weekly_quota) do
        {div_dated_quota, distribute_first_available_week(employee, div_weekly_quota, output_file)}
      else
        Logger.info(
          "Skipping vacation week assignment - employee cannot take any weeks off in this rating period."
        )

        max_days = min(div(max_minutes, 8 * 60), employee_balance.dated_quota)

        {distribute_days_balance(employee, max_days, div_dated_quota, [], output_file),
         div_weekly_quota}
      end
    else
      Logger.info(
        "Skipping assignment for this employee - simplifying to only assign if a single interval encompasses the rating period."
      )

      {div_dated_quota, div_weekly_quota}
    end
  end

  defp distribute_days_balance(
         _employee,
         max_days,
         div_day_quota,
         _emp_selected_days,
         _output_file
       )
       when max_days == 0 do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this rating period."
    )

    div_day_quota
  end

  defp distribute_days_balance(
         _employee,
         max_days,
         div_day_quota,
         emp_selected_days,
         _output_file
       )
       when max_days == length(emp_selected_days) or div_day_quota == [] do
    div_day_quota
  end

  defp distribute_days_balance(employee, max_days, div_day_quota, emp_selected_days, output_file) do
    {selected_day, remaining_quota} = List.pop_at(div_day_quota, 0)

    Logger.info("assigned day - #{selected_day.date}")

    File.write(
       output_file,
          Draft.EmployeeVacationAssignment.to_parts(%{
            employee_id: employee.employee_id,
            vacation_interval_type: "0",
            forced?: true,
            start_date: selected_day.date,
            end_date: selected_day.date
          }), [:append]
       )

    div_day_quota =
      distribute_days_balance(
        employee,
        max_days,
        remaining_quota,
        [
          selected_day.date | emp_selected_days
        ],
        output_file
      )

    div_day_quota
  end

  defp distribute_first_available_week(employee, div_weekly_quota, output_file) do
    first_avail_quota = List.first(div_weekly_quota)
    new_quota = first_avail_quota.quota - 1
    div_weekly_quota = update_division_quota(div_weekly_quota, 0, new_quota)
    File.write(
      output_file,
         Draft.EmployeeVacationAssignment.to_parts(%{
           employee_id: employee.employee_id,
           vacation_interval_type: "1",
           forced?: true,
           start_date: first_avail_quota.start_date,
           end_date: first_avail_quota.end_date
         }), [:append]
      )

    Logger.info(
      "assigned week - #{first_avail_quota.start_date} - #{first_avail_quota.end_date}. #{
        new_quota
      } more openings for this week.\n"
    )

    div_weekly_quota
  end

  defp update_division_quota(division_quota, pos, new_quota)

  defp update_division_quota(division_quota, pos, 0) do
    List.delete_at(division_quota, pos)
  end

  defp update_division_quota(division_quota, pos, new_quota) do
    List.update_at(division_quota, pos, fn q -> %{q | quota: new_quota} end)
  end
end

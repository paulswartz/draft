defmodule Draft.BasicVacationDistribution do
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.DivisionVacationDayQuota
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationQuota
  alias Draft.Repo

  import Ecto.Query
  require Logger

  def basic_vacation_distribution() do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])
    Enum.each(bid_rounds, &assign_vacation_for_round(&1))
  end

  defp assign_vacation_for_round(round) do
    Logger.info(
      "======================================================================\nSTARTING NEW ROUND: #{round.rank} - #{
        round.division_id
      } - #{round.division_description}(#{round.round_id}) (picking between #{
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

    Enum.reduce(bid_groups, {div_dated_quota, div_weekly_quota}, fn group,
                                                                    {dated_quota, weekly_quota} ->
      assign_vacation_for_group(group, round, dated_quota, weekly_quota)
    end)
  end

  defp assign_vacation_for_group(group, round, div_dated_quota, div_weekly_quota) do
    Logger.info(
      "--------------------------------------------------------------\nSTARTING NEW GROUP: #{group.group_number} (cutoff time #{
        group.cutoff_datetime
      })\n"
    )

    group_employees =
      Repo.all(
        from e in EmployeeRanking,
          where:
            e.round_id == ^group.round_id and e.process_id == ^group.process_id and
              e.group_number == ^group.group_number,
          order_by: [asc: e.rank]
      )

    {div_dated_quota, div_weekly_quota} =
      Enum.reduce(group_employees, {div_dated_quota, div_weekly_quota}, fn employee,
                                                                           {dated_quota,
                                                                            weekly_quota} ->
        assign_vacation_for_employee(
          employee,
          round,
          dated_quota,
          weekly_quota
        )
      end)

    {div_dated_quota, div_weekly_quota}
  end

  defp assign_vacation_for_employee(
        employee,
        round,
        div_dated_quota,
        div_weekly_quota
      ) do
    Logger.info("Distributing vacation for employee #{employee.rank} - #{employee.employee_id}")

    employee_balances =
      Repo.all(
        from q in EmployeeVacationQuota,
          where:
            q.employee_id == ^employee.employee_id and
              q.interval_start_date <= ^round.rating_period_start_date and
              q.interval_end_date >= ^round.rating_period_start_date
      )

    if length(employee_balances) == 1 do
      employee_balance = List.first(employee_balances)

      Logger.info(
        "Employee #{employee.employee_id} balance for period #{
          employee_balance.interval_start_date
        } - #{employee_balance.interval_end_date}: #{employee_balance.weekly_quota} max weeks, #{
          employee_balance.dated_quota
        } max days, #{employee_balance.maximum_minutes} max minutes"
      )

      max_weeks = div(employee_balance.maximum_minutes, 2400)

      if max_weeks > 0 do
        {div_dated_quota, distribute_week(employee, div_weekly_quota)}
      else
        {div_dated_quota, div_weekly_quota}
      end
    else
      {div_dated_quota, div_weekly_quota}
    end
  end

  defp distribute_week(employee, div_weekly_quota) do
    if length(div_weekly_quota) == 0 do
      Logger.info("Skipping vacation week assignment - no available weeks remaining.\n")
      div_weekly_quota
    else
      first_avail_quota = List.first(div_weekly_quota)
      new_quota = first_avail_quota.quota - 1

      if new_quota == 0 do
        div_weekly_quota = List.delete_at(div_weekly_quota, 0)

        Logger.info(
          "assigned week - #{first_avail_quota.start_date} - #{first_avail_quota.end_date}. No more openings for this week.\n"
        )

        div_weekly_quota
      else
        div_weekly_quota =
          List.update_at(div_weekly_quota, 0, fn q -> %{q | quota: new_quota} end)

        Logger.info(
          "assigned week - #{first_avail_quota.start_date} - #{first_avail_quota.end_date}. #{
            new_quota
          } more openings for this week.\n"
        )

        div_weekly_quota
      end
    end
  end
end

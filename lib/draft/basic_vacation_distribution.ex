defmodule Draft.BasicVacationDistribution do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has any weeks left in their vacation balance, they will be assigned available vacation weeks for their division.
  Otherwise, they will be assigned days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.DivisionVacationDayQuota
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationAssignment
  alias Draft.EmployeeVacationQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Repo
  alias Draft.VacationQuotaSetup

  require Logger

  @spec basic_vacation_distribution([{module(), String.t()}]) :: [EmployeeVacationAssignment.t()]
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences, using vacation data from the given files. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def basic_vacation_distribution(vacation_files) do
    _rows_updated = VacationQuotaSetup.update_vacation_quota_data(vacation_files)

    basic_vacation_distribution()
  end

  @spec basic_vacation_distribution() :: [EmployeeVacationAssignment.t()]
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def basic_vacation_distribution do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])
    Enum.flat_map(bid_rounds, &assign_vacation_for_round(&1))
  end

  defp assign_vacation_for_round(round) do
    Logger.info(
      "===================================================================================================\nSTARTING NEW ROUND: #{
        round.rank
      } - #{round.division_id} - #{round.division_description}(#{round.round_id}) (picking between #{
        round.round_opening_date
      } and #{round.round_closing_date} for the rating period #{round.rating_period_start_date} - #{
        round.rating_period_end_date
      })\n"
    )

    bid_groups =
      Repo.all(
        from g in BidGroup,
          where: g.round_id == ^round.round_id and g.process_id == ^round.process_id,
          order_by: [asc: g.group_number]
      )

    Enum.flat_map(
      bid_groups,
      fn group ->
        assign_vacation_for_group(group, round)
      end
    )
  end

  defp assign_vacation_for_group(
         group,
         round
       ) do
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

    Enum.flat_map(
      group_employees,
      fn employee ->
        assign_vacation_for_employee(
          employee,
          round
        )
      end
    )
  end

  defp assign_vacation_for_employee(
         employee,
         round
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

    case employee_balances do
      [employee_balance] ->
        Logger.info(
          "Employee balance for period #{employee_balance.interval_start_date} - #{
            employee_balance.interval_end_date
          }: #{employee_balance.weekly_quota} max weeks, #{employee_balance.dated_quota} max days, #{
            employee_balance.maximum_minutes
          } max minutes"
        )

        max_minutes = employee_balance.maximum_minutes

        anniversary_upcoming =
          !is_nil(employee_balance.available_after_date) &&
            !(Date.compare(employee_balance.available_after_date, round.rating_period_start_date) ==
                :lt)

        # In the future, this would also take into consideration if an employee is working 5/2 or 4/3
        num_hours_per_day =
          if String.starts_with?(
               Draft.JobClassHelpers.get_selection_set(employee.job_class),
               "FT"
             ),
             do: 8,
             else: 6

        # Cap weeks by the maximum number of minutes an operator has left to take off
        max_weeks =
          min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

        # subtract any unearned time
        max_weeks =
          max(
            0,
            if anniversary_upcoming do
              max_weeks - employee_balance.available_after_weekly_quota
            else
              max_weeks
            end
          )

        has_anniversary_date_during_rating_period =
          !is_nil(employee_balance.available_after_date) &&
            Enum.member?(
              Date.range(round.rating_period_start_date, round.rating_period_end_date),
              employee_balance.available_after_date
            )

        assignment_range_end_date =
          if has_anniversary_date_during_rating_period do
            # TODO confirm vacation time not earned until the day of - maybe rename this field to be more descriptive.
            Date.add(employee_balance.available_after_date, -1)
          else
            round.rating_period_end_date
          end

        assigned_weeks =
          distribute_weeks_balance(
            round.division_id,
            employee,
            max_weeks,
            round.rating_period_start_date,
            assignment_range_end_date
          )

        max_days = min(div(max_minutes, num_hours_per_day * 60), employee_balance.dated_quota)

        max_days =
          max(
            0,
            if anniversary_upcoming do
              max_days - employee_balance.available_after_dated_quota
            else
              max_days
            end
          )

        assigned_days =
          distribute_days_balance(
            round.division_id,
            employee,
            max_days,
            assigned_weeks,
            round.rating_period_start_date,
            assignment_range_end_date
          )

        assigned_weeks ++ assigned_days

      [] ->
        Logger.info(
          "Skipping assignment for this employee - no quota interval encompassing the rating period."
        )

        []

      _employee_balances ->
        Logger.info(
          "Skipping assignment for this employee - simplifying to only assign if a single interval encompasses the rating period."
        )

        []
    end
  end

  defp distribute_days_balance(
         division_id,
         employee,
         max_days,
         assigned_weeks,
         range_start_date,
         range_end_Date
       )

  defp distribute_days_balance(
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

  defp distribute_days_balance(
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

  defp distribute_days_balance(
         _round,
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

  defp distribute_weeks_balance(
         division_id,
         employee,
         max_weeks,
         range_start_date,
         range_end_date
       )

  defp distribute_weeks_balance(_division_id, _employee, 0, _range_start_date, _range_end_date) do
    Logger.info(
      "Skipping vacation week assignment - employee cannot take any weeks off in this range."
    )

    []
  end

  defp distribute_weeks_balance(
         division_id,
         employee,
         max_weeks,
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

    available_weeks =
      Repo.all(
        from w in DivisionVacationWeekQuota,
          as: :division_week_quota,
          where:
            w.division_id == ^division_id and w.quota > 0 and w.is_restricted_week == false and
              w.employee_selection_set == ^selection_set and
              ^range_start_date <= w.start_date and
              ^range_end_date >= w.end_date and
              not exists(conflicting_selected_vacation_query),
          order_by: [asc: w.start_date],
          limit: ^max_weeks
      )

    distribute_avaliable_weeks(employee, available_weeks)
  end

  defp distribute_avaliable_weeks(employee, available_weeks)

  defp distribute_avaliable_weeks(_employee, []) do
    Logger.info("No more vacation weeks available")
    []
  end

  defp distribute_avaliable_weeks(employee, available_weeks) do
    Enum.map(available_weeks, &distribute_single_week(employee, &1))
  end

  defp distribute_single_week(employee, assigned_week) do
    new_quota = assigned_week.quota - 1
    changeset = DivisionVacationWeekQuota.changeset(assigned_week, %{quota: new_quota})
    Repo.update(changeset)

    Logger.info(
      "assigned week - #{assigned_week.start_date} - #{assigned_week.end_date}. #{new_quota} more openings for this week.\n"
    )

    %EmployeeVacationAssignment{
      employee_id: employee.employee_id,
      is_week?: true,
      start_date: assigned_week.start_date,
      end_date: assigned_week.end_date
    }
  end
end

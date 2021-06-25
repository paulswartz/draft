defmodule Draft.BasicVacationDistribution do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has any weeks left in their vacation balance, they will be assigned available vacation weeks for their division.
  Otherwise, they will be assigned days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationAssignment
  alias Draft.EmployeeVacationQuota
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

        # In the future, this would also take into consideration if an employee is working 5/2 or 4/3
        num_hours_per_day =
          if String.starts_with?(
               Draft.JobClassHelpers.get_selection_set(employee.job_class),
               "FT"
             ),
             do: 8,
             else: 6

        # Cap weeks by the maximum number of paid vacation minutes an operator has remaining
        max_weeks =
          min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

        anniversary_quota = EmployeeVacationQuota.get_anniversary_quota(employee_balance)

        assigned_weeks =
          Draft.VacationWeekDistribution.distribute_weeks_balance(
            round,
            employee,
            max_weeks,
            anniversary_quota
          )

        max_days = min(div(max_minutes, num_hours_per_day * 60), employee_balance.dated_quota)

        assigned_days =
          Draft.VacationDayDistribution.distribute_days_balance(
            round,
            employee,
            max_days,
            assigned_weeks,
            anniversary_quota
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
end

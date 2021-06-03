defmodule Draft.BasicVacationDistribution do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has at least a week in their vacation balance, they will be assigned a week available for their division.
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
  alias Draft.Repo

  require Logger

  @spec basic_vacation_distribution :: :ok
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def basic_vacation_distribution do
    output_file_path = "data/test_vacation_assignment_output.csv"

    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])
    {:ok, output_file} = File.open(output_file_path, [:write])
    Enum.each(bid_rounds, &assign_vacation_for_round(&1, output_file_path))
    File.close(output_file)
  end

  defp assign_vacation_for_round(round, output_file_path) do
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

    Enum.each(
      bid_groups,
      fn group ->
        assign_vacation_for_group(group, round, output_file_path)
      end
    )
  end

  defp assign_vacation_for_group(
         group,
         round,
         output_file_path
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

    Enum.each(
      group_employees,
      fn employee ->
        assign_vacation_for_employee(
          employee,
          round,
          output_file_path
        )
      end
    )
  end

  defp assign_vacation_for_employee(
         employee,
         round,
         output_file_path
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
          if String.starts_with?(get_selection_set(employee.job_class), "FT"),
            do: 8,
            else: 6

        max_weeks =
          min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

        can_take_weeks_off = max_weeks > 0

        if can_take_weeks_off do
          distribute_first_available_week(round, employee, output_file_path)
        else
          Logger.info(
            "Skipping vacation week assignment - employee cannot take any weeks off in this rating period."
          )

          max_days = min(div(max_minutes, num_hours_per_day * 60), employee_balance.dated_quota)

          distribute_days_balance(round, employee, max_days, output_file_path)
        end

      _empty_employee_balance ->
        Logger.info(
          "Skipping assignment for this employee - simplifying to only assign if a single interval encompasses the rating period."
        )
    end
  end

  defp distribute_days_balance(
         round,
         employee,
         max_days,
         output_file_path
       )

  defp distribute_days_balance(
         _round,
         _employee,
         0,
         _output_file_path
       ) do
    Logger.info(
      "Skipping vacation day assignment - employee cannot take any days off in this rating period."
    )
  end

  defp distribute_days_balance(
         round,
         employee,
         max_days,
         output_file_path
       ) do
    selection_set = get_selection_set(employee.job_class)

    first_available_days =
      Repo.all(
        from d in DivisionVacationDayQuota,
          where:
            d.division_id == ^round.division_id and d.quota > 0 and
              d.employee_selection_set == ^selection_set and
              d.date >= ^round.rating_period_start_date and
              d.date <= ^round.rating_period_end_date,
          order_by: [asc: d.date],
          limit: ^max_days
      )

    Enum.each(first_available_days, fn date_quota ->
      Repo.update(DivisionVacationDayQuota.changeset(date_quota, %{quota: date_quota.quota - 1}))
    end)

    Enum.each(first_available_days, &distribute_single_day(employee, &1, output_file_path))
  end

  defp distribute_single_day(employee, selected_day, output_file_path) do
    Logger.info("assigned day - #{selected_day.date}")

    :ok =
      File.write(
        output_file_path,
        EmployeeVacationAssignment.to_csv_row(%EmployeeVacationAssignment{
          employee_id: employee.employee_id,
          vacation_interval_type: "0",
          forced?: true,
          start_date: selected_day.date,
          end_date: selected_day.date
        }),
        [:append]
      )
  end

  defp get_selection_set(job_type) do
    full_time = "FTVacQuota"
    part_time = "PTVacQuota"

    job_class_map = %{
      "000100" => full_time,
      "000300" => full_time,
      "000800" => full_time,
      "001100" => part_time,
      "000200" => part_time,
      "000900" => part_time
    }

    job_class_map[job_type]
  end

  defp distribute_first_available_week(round, employee, output_file_path) do
    selection_set = get_selection_set(employee.job_class)

    first_avail_week =
      Repo.all(
        from w in DivisionVacationWeekQuota,
          where:
            w.division_id == ^round.division_id and w.quota > 0 and w.is_restricted_week == false and
              w.employee_selection_set == ^selection_set and
              ^round.rating_period_start_date <= w.start_date and
              ^round.rating_period_end_date >= w.end_date,
          order_by: [asc: w.start_date],
          limit: 1
      )

    case first_avail_week do
      [first_avail_week] ->
        new_quota = first_avail_week.quota - 1
        changeset = DivisionVacationWeekQuota.changeset(first_avail_week, %{quota: new_quota})
        Repo.update(changeset)

        :ok =
          File.write(
            output_file_path,
            EmployeeVacationAssignment.to_csv_row(%EmployeeVacationAssignment{
              employee_id: employee.employee_id,
              vacation_interval_type: "1",
              forced?: true,
              start_date: first_avail_week.start_date,
              end_date: first_avail_week.end_date
            }),
            [:append]
          )

        Logger.info(
          "assigned week - #{first_avail_week.start_date} - #{first_avail_week.end_date}. #{
            new_quota
          } more openings for this week.\n"
        )

      _no_available_weeks ->
        Logger.info("No more vacation weeks available")
    end
  end
end

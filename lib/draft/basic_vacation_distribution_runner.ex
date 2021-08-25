defmodule Draft.BasicVacationDistributionRunner do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has any weeks left in their vacation balance, they will be assigned available vacation weeks for their division.
  Otherwise, they will be assigned days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationQuota
  alias Draft.GenerateVacationDistribution
  alias Draft.Repo
  alias Draft.VacationDistribution
  alias Draft.VacationQuotaSetup

  require Logger

  @type distribution_result() :: {:ok, [VacationDistribution.t()]} | {:error, any()}

  @spec run_all_rounds([{module(), String.t()}]) ::
          distribution_result()
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences, using vacation data from the given files. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def run_all_rounds(vacation_files) do
    _rows_updated = VacationQuotaSetup.update_vacation_quota_data(vacation_files)

    run_all_rounds()
  end

  @spec run_all_rounds() :: distribution_result()
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def run_all_rounds do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])

    process_until_error(
      bid_rounds,
      &assign_vacation_for_round(&1)
    )
  end

  @spec distribute_vacation_to_group(
          %{
            group_number: integer(),
            process_id: String.t(),
            round_id: String.t()
          },
          Draft.IntervalType.t()
        ) :: {:ok, VacationDistribution.t()} | {:error, any()}
  @doc """
  Distribute vacation to all employees in the given group in seniority order.
  """
  def distribute_vacation_to_group(
        %{
          round_id: round_id,
          process_id: process_id,
          group_number: group_number
        },
        vacation_interval
      ) do
    group =
      Repo.get_by(BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    if group do
      round = Repo.get_by!(BidRound, round_id: round_id, process_id: process_id)
      assign_vacation_for_group(round, group, vacation_interval)
    else
      {:error, "No group found with
  round_id: #{round_id},
  process_id: #{process_id},
  group_number: #{group_number}
"}
    end
  end

  @spec process_until_error([], (any -> distribution_result())) :: distribution_result()
  defp process_until_error(list, process_fn) do
    Enum.reduce_while(
      list,
      {:ok, []},
      &handle_distribution_results(
        process_fn.(&1),
        &2
      )
    )
  end

  defp handle_distribution_results({:ok, assignments}, {:ok, previous_assignments}) do
    {:cont, {:ok, assignments ++ previous_assignments}}
  end

  defp handle_distribution_results({:error, errors}, _previous_assignments) do
    {:halt, {:error, errors}}
  end

  @spec assign_vacation_for_round(BidRound.t()) ::
          distribution_result()
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

    interval_type = Draft.BidSession.vacation_interval(round)

    process_until_error(
      bid_groups,
      &assign_vacation_for_group(round, &1, interval_type)
    )
  end

  @spec assign_vacation_for_group(BidRound.t(), BidGroup.t(), Draft.IntervalType.t()) ::
          distribution_result()
  defp assign_vacation_for_group(round, group, interval_type) do
    Logger.info(
      "-------------------------------------------------------------------------------------------------\nSTARTING NEW GROUP: #{
        group.group_number
      } (cutoff time #{group.cutoff_datetime})\n"
    )

    distribution_run_id = Draft.VacationDistributionRun.insert(group)

    group_employees =
      Repo.all(
        from e in EmployeeRanking,
          where:
            e.round_id == ^group.round_id and e.process_id == ^group.process_id and
              e.group_number == ^group.group_number,
          order_by: [asc: e.rank]
      )

    assigned_vacation =
      process_until_error(
        group_employees,
        &assign_vacation_for_employee(
          &1,
          round,
          distribution_run_id,
          interval_type
        )
      )

    _completed_vacation_run = Draft.VacationDistributionRun.mark_complete(distribution_run_id)
    assigned_vacation
  end

  @spec assign_vacation_for_employee(
          EmployeeRanking.t(),
          BidRound.t(),
          integer(),
          Draft.IntervalType.t()
        ) ::
          distribution_result()
  defp assign_vacation_for_employee(
         employee,
         round,
         distribution_run_id,
         interval_type
       ) do
    Logger.info("-------\nDistributing vacation for employee #{employee.rank}")

    # For now, only getting balance if the balance interval covers the entire rating period.
    employee_balances =
      Repo.all(
        from q in EmployeeVacationQuota,
          where:
            q.employee_id == ^employee.employee_id and
              (q.interval_start_date <= ^round.rating_period_start_date and
                 q.interval_end_date >= ^round.rating_period_end_date)
      )

    assign_vacation(round, employee, distribution_run_id, employee_balances, interval_type)
  end

  @spec assign_vacation(
          BidRound.t(),
          EmployeeRanking.t(),
          integer(),
          [EmployeeVacationQuota.t()],
          Draft.IntervalType.t()
        ) ::
          distribution_result()
  defp assign_vacation(round, employee, distribution_run_id, employee_balances, interval_type)

  defp assign_vacation(round, employee, distribution_run_id, [employee_balance], interval_type) do
    Logger.info(
      "Employee balance for period #{employee_balance.interval_start_date} - #{
        employee_balance.interval_end_date
      }: #{employee_balance.weekly_quota} max weeks, #{employee_balance.dated_quota} max days, #{
        employee_balance.maximum_minutes
      } max minutes"
    )

    max_minutes = employee_balance.maximum_minutes

    # Assuming 5/2 schedule for now
    num_hours_per_day = Draft.JobClassHelpers.num_hours_per_day(employee.job_class, :five_two)

    anniversary_quota = EmployeeVacationQuota.get_anniversary_quota(employee_balance)

    # Cap vacation by the maximum number of paid vacation minutes an operator has remaining
    # In the future, this will need to take into account whether an employee is working
    # 4 days a week or 5 (8 or 10 hour days)
    max_quota =
      case interval_type do
        :week ->
          min(
            div(max_minutes, 60 * Draft.JobClassHelpers.num_hours_per_week(employee.job_class)),
            employee_balance.weekly_quota
          )

        :day ->
          min(div(max_minutes, num_hours_per_day * 60), employee_balance.dated_quota)
      end

    vacation_distributions =
      GenerateVacationDistribution.Voluntary.generate(
        distribution_run_id,
        round,
        employee,
        max_quota,
        anniversary_quota,
        interval_type
      )

    case Draft.VacationDistribution.add_distributions_to_run(
           distribution_run_id,
           vacation_distributions
         ) do
      {:ok, _result} ->
        {:ok, vacation_distributions}

      {:error, errors} ->
        {:error, "Error saving vacation distributions. #{inspect(errors)}"}
    end
  end

  defp assign_vacation(_round, _employee, _distribution_run_id, [], _interval_type) do
    Logger.info(
      "Skipping assignment for this employee - no quota interval encompassing the rating period."
    )

    {:ok, []}
  end

  defp assign_vacation(
         _round,
         _employee,
         _distribution_run_id,
         _employee_balances,
         _interval_type
       ) do
    Logger.info(
      "Skipping assignment for this employee - simplifying to only assign if a single interval encompasses the rating period."
    )

    {:ok, []}
  end
end

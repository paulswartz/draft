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

  @spec run_all_rounds([{module(), String.t()}]) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences, using vacation data from the given files. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def run_all_rounds(vacation_files) do
    _rows_updated = VacationQuotaSetup.update_vacation_quota_data(vacation_files)

    run_all_rounds()
  end

  @spec run_all_rounds() :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def run_all_rounds do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])

    Enum.reduce_while(
      bid_rounds,
      {:ok, []},
      &handle_distribution_results(assign_vacation_for_round(&1), &2)
    )
  end

  defp handle_distribution_results({:ok, assignments}, previous_assignments) do
    {:cont, {:ok, assignments ++ previous_assignments}}
  end

  defp handle_distribution_results({:error, errors}, _previous_assignments) do
    {:halt, {:error, errors}}
  end

  @spec assign_vacation_for_round(BidRound.t()) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
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

    Enum.reduce_while(
      bid_groups,
      {:ok, []},
      fn group, acc ->
        handle_distribution_results(assign_vacation_for_group(round, group), acc)
      end
    )
  end

  @spec distribute_vacation_to_group(%{
          :group_number => integer(),
          :process_id => String.t(),
          :round_id => String.t()
        }) :: {:ok, VacationDistribution.t()} | {:error, any()}
  @doc """
  Distribute vacation to all employees in the given group in seniority order.
  """
  def distribute_vacation_to_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
    round = Repo.get_by!(BidRound, round_id: round_id, process_id: process_id)

    group =
      Repo.get_by!(BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    assign_vacation_for_group(round, group)
  end

  @spec assign_vacation_for_group(BidRound.t(), BidGroup.t()) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
  defp assign_vacation_for_group(round, group) do
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
      Enum.reduce_while(
        group_employees,
        {:ok, []},
        fn employee, acc ->
          handle_distribution_results(
            assign_vacation_for_employee(
              employee,
              round,
              distribution_run_id
            ),
            acc
          )
        end
      )

    _completed_vacation_run = Draft.VacationDistributionRun.mark_complete(distribution_run_id)
    assigned_vacation
  end

  @spec assign_vacation_for_employee(EmployeeRanking.t(), BidRound.t(), integer()) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
  defp assign_vacation_for_employee(
         employee,
         round,
         distribution_run_id
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

    assign_vacation(round, employee, distribution_run_id, employee_balances)
  end

  @spec assign_vacation(BidRound.t(), EmployeeRanking.t(), integer(), [EmployeeVacationQuota.t()]) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
  defp assign_vacation(round, employee, distribution_run_id, employee_balances)

  defp assign_vacation(round, employee, distribution_run_id, [employee_balance]) do
    Logger.info(
      "Employee balance for period #{employee_balance.interval_start_date} - #{
        employee_balance.interval_end_date
      }: #{employee_balance.weekly_quota} max weeks, #{employee_balance.dated_quota} max days, #{
        employee_balance.maximum_minutes
      } max minutes"
    )

    max_minutes = employee_balance.maximum_minutes

    num_hours_per_day = Draft.JobClassHelpers.num_hours_per_day(employee.job_class)

    # Cap weeks by the maximum number of paid vacation minutes an operator has remaining
    max_weeks = min(div(max_minutes, 60 * num_hours_per_day * 5), employee_balance.weekly_quota)

    anniversary_quota = EmployeeVacationQuota.get_anniversary_quota(employee_balance)

    assigned_weeks =
      GenerateVacationDistribution.Weeks.generate(
        distribution_run_id,
        round,
        employee,
        max_weeks,
        anniversary_quota
      )

    max_days = min(div(max_minutes, num_hours_per_day * 60), employee_balance.dated_quota)

    assigned_days =
      GenerateVacationDistribution.Days.generate(
        distribution_run_id,
        round,
        employee,
        max_days,
        assigned_weeks,
        anniversary_quota
      )

    case Draft.VacationDistribution.add_distributions_to_run(
           distribution_run_id,
           assigned_weeks ++ assigned_days
         ) do
      {:ok, _result} ->
        {:ok, assigned_weeks ++ assigned_days}

      {:error, errors} ->
        {:error, "Error saving vacation distributions. #{inspect(errors)}"}
    end
  end

  defp assign_vacation(_round, _employee, _distribution_run_id, []) do
    Logger.info(
      "Skipping assignment for this employee - no quota interval encompassing the rating period."
    )

    []
  end

  defp assign_vacation(_round, _employee, _distribution_run_id, _employee_balances) do
    Logger.info(
      "Skipping assignment for this employee - simplifying to only assign if a single interval encompasses the rating period."
    )

    []
  end
end

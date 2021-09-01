defmodule Draft.BasicVacationDistributionRunner do
  @moduledoc """
  Simulate distributing vacation for all employees based on their rank in the given rounds / groups.
  If an employee has any weeks left in their vacation balance, they will be assigned available vacation weeks for their division.
  Otherwise, they will be assigned days available for their division, capped by the number of days in their balance.
  """
  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.BidSession
  alias Draft.GenerateVacationDistribution
  alias Draft.Repo
  alias Draft.VacationDistribution

  require Logger

  @type distribution_result() :: {:ok, [VacationDistribution.t()]} | {:error, any()}

  @spec run_all_rounds(0..100) :: distribution_result()
  @doc """
  Distirbutes vacation to employees in each round without consideration for preferences. Outputs verbose logs as vacation is assigned,
  and creates a CSV file in the required HASTUS format.
  """
  def run_all_rounds(percent_to_force \\ 0) do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])

    process_until_error(
      bid_rounds,
      &assign_vacation_for_round(&1, percent_to_force)
    )
  end

  @spec distribute_vacation_to_group(
          %{
            group_number: integer(),
            process_id: String.t(),
            round_id: String.t()
          },
          0..100
        ) :: {:ok, VacationDistribution.t()} | {:error, any()}
  @doc """
  Distribute vacation to all employees in the given group in seniority order.
  """
  def distribute_vacation_to_group(
        %{
          round_id: round_id,
          process_id: process_id,
          group_number: group_number
        } = group_key,
        percent_to_force \\ 0
      ) do
    group =
      Repo.get_by(BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    if group do
      session = Draft.BidSession.vacation_session(group_key)
      assign_vacation_for_group(session, group, percent_to_force)
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

  @spec assign_vacation_for_round(BidRound.t(), 0..100) ::
          distribution_result()
  defp assign_vacation_for_round(round, percent_to_force) do
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

    session = Draft.BidSession.vacation_session(round)

    process_until_error(
      bid_groups,
      &assign_vacation_for_group(session, &1, percent_to_force)
    )
  end

  @spec assign_vacation_for_group(BidSession.t(), BidGroup.t(), 0) ::
          distribution_result()

  defp assign_vacation_for_group(session, group, 0) do
    Logger.info(
      "-------------------------------------------------------------------------------------------------\nSTARTING NEW GROUP: #{
        group.group_number
      } (cutoff time #{group.cutoff_datetime})\n"
    )

    distribution_run_id = Draft.VacationDistributionRun.insert(group)

    group
    |> Draft.EmployeeRanking.all_operators_in_group()
    |> Enum.map(
      &Draft.EmployeeVacationQuotaSummary.get(
        &1,
        session.rating_period_start_date,
        session.rating_period_end_date,
        session.type_allowed
      )
    )
    |> process_until_error(&distribute_voluntary_vacation(distribution_run_id, session, &1))
  end

  defp assign_vacation_for_group(session, group, percent_to_force) do
    Logger.info(
      "-------------------------------------------------------------------------------------------------\nSTARTING NEW GROUP: #{
        group.group_number
      } (cutoff time #{group.cutoff_datetime})\n"
    )

    distribution_run_id = Draft.VacationDistributionRun.insert(group)

    all_remaining_employees =
      group
      |> Draft.EmployeeRanking.all_operators_in_and_after_group()
      |> Enum.map(
        &Draft.EmployeeVacationQuotaSummary.get(
          &1,
          session.rating_period_start_date,
          session.rating_period_end_date,
          session.type_allowed
        )
      )

    count_to_force = Draft.DivisionQuota.remaining_quota(session, percent_to_force)

    vacation_distributions =
      distribute_vacation(
        distribution_run_id,
        session,
        count_to_force,
        group.group_number,
        all_remaining_employees,
        []
      )

    _completed_vacation_run = Draft.VacationDistributionRun.mark_complete(distribution_run_id)
    vacation_distributions
  end

  defp distribute_vacation(
         _run_id,
         _session,
         _count_to_force,
         _group_number,
         [],
         acc_distributions
       ) do
    {:ok, acc_distributions}
  end

  defp distribute_vacation(
         _run_id,
         _session,
         _count_to_force,
         group_number,
         [%{group_number: first_emp_group_number}],
         acc_distributions
       )
       when first_emp_group_number != group_number do
    # Finished distributing to the target group
    {:ok, acc_distributions}
  end

  defp distribute_vacation(
         run_id,
         session,
         count_to_force,
         group_number,
         [first_emp | remaining_emps] = all_remaining_employees,
         acc_distributions
       ) do
    poe = Draft.PointOfEquivalence.calculate(all_remaining_employees, count_to_force)

    if poe.has_poe_been_reached do
      employee_to_group =
        Map.new(
          all_remaining_employees,
          &{&1.employee_id, &1.group_number}
        )

      distribute_forced_vacation(
        run_id,
        session,
        poe.employees_to_force,
        group_number,
        employee_to_group,
        acc_distributions
      )
    else
      {:ok, first_emp_distributions} = distribute_voluntary_vacation(run_id, session, first_emp)

      distribute_vacation(
        run_id,
        session,
        max(count_to_force - length(first_emp_distributions), 0),
        group_number,
        remaining_emps,
        acc_distributions ++ first_emp_distributions
      )
    end
  end

  defp distribute_forced_vacation(
         run_id,
         session,
         employees_to_force,
         group_number,
         employee_to_group,
         acc_distributions
       ) do
    session
    |> GenerateVacationDistribution.Forced.generate_for_employees(
      employees_to_force,
      acc_distributions
    )
    |> handle_forced_vacation_results(
      run_id,
      group_number,
      employee_to_group
    )
  end

  @spec handle_forced_vacation_results(
          {:ok, [VacationDistribution.t()]} | :error,
          Draft.VacationDistributionRun.id(),
          integer(),
          %{String.t() => integer()}
        ) :: {:ok, [VacationDistribution.t()] | {:error, any}}

  defp handle_forced_vacation_results(:error, _run_id, _group_number, _employee_to_group_number) do
    {:error, "No valid way to force the remaining employees"}
  end

  defp handle_forced_vacation_results(
         {:ok, distributions},
         run_id,
         group_number,
         employee_to_group_number
       ) do
    # Filter to only forced distributions for the current group
    forced_distributions_for_group =
      Enum.filter(
        distributions,
        &(Map.get(employee_to_group_number, &1.employee_id) == group_number || &1.is_forced)
      )

    # Only save the forced distributions for the group -- any voluntary distributions
    # would have been previously saved.
    {:ok, _result} =
      Draft.VacationDistribution.add_distributions_to_run(run_id, forced_distributions_for_group)

    {:ok, distributions}
  end

  @spec distribute_voluntary_vacation(
          Draft.VacationDistributionRun.id(),
          BidSession.t(),
          Draft.EmployeeVacationQuotaSummary.t()
        ) ::
          distribution_result()
  defp distribute_voluntary_vacation(distribution_run_id, session, employee_quota_summary) do
    vacation_distributions =
      GenerateVacationDistribution.Voluntary.generate(
        distribution_run_id,
        session,
        employee_quota_summary
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
end

defmodule Draft.GenerateVacationDistribution.Forced do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to all employees in the given group,
  ensuring that it will be possible to force all remaining employees to take vacation as well.
  """
  import Ecto.Query
  alias Draft.DivisionVacationWeekQuota
  alias Draft.Repo
  alias Draft.VacationDistribution
  require Logger

  @type acc_vacation_distributions() :: %{Date.t() => MapSet.t(VacationDistribution.t())}

  @type evaluation_strategy ::
          :evaluate_until_first_solution_found | :evaluate_all_possible_solutions

  @type calculated_employee_quota() :: %{
          remaining_quota: integer(),
          available_quota: [%{start_date: Date.t(), quota: non_neg_integer()}],
          employee_id: String.t(),
          job_class: String.t()
        }

  @spec generate_for_group(
          %{
            round_id: String.t(),
            process_id: String.t(),
            group_number: integer()
          },
          evaluation_strategy()
        ) :: {:ok, [VacationDistribution.t()]} | {:error, any()}
  @doc """
  Generate vacation assignments that force all employees in the given group (and all remaining
  groups after them) to use all of their remaining full vacation weeks. Assignments are made in
  seniority order, so the most senior operator is awarded vacation as long as it is possible
  force all remaining operators to use all their vacation time.
  """
  def generate_for_group(
        %{
          round_id: round_id,
          process_id: process_id,
          group_number: group_number
        },
        evaluation_strategy \\ :evaluate_until_first_solution_found
      ) do
    Logger.info("Starting Distribution generation: #{inspect(DateTime.utc_now())}")

    group =
      Repo.get_by(Draft.BidGroup,
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      )

    if group do
      round = Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      # The use of `get_all_operators_in_or_after_group` here is a temporary simplification;
      # We ultimately won't need to force all operators in the specified group & all following.
      # We will only need to generate distributions for the curent group, ensuring that the subset
      # of the least senior operators who will need to be forced can still be forced in a valid
      # way.
      employee_quotas =
        group
        |> get_all_operators_in_or_after_group()
        |> Enum.map(&calculated_quota(round, &1, :week))

      acc = %{}
      memo = :ets.new(:memo, [:set, :private])
      dists = generate_distributions(round, employee_quotas, acc, memo)

      result = take_result(dists, evaluation_strategy)
      Logger.info("Finishing Distribution generation: #{inspect(DateTime.utc_now())}")
      # ensure we clean up the ETS table
      :ets.delete(memo)
      result
    else
      {:error,
       "No group found with round_id: #{round_id}, process_id: #{process_id}, group_number: #{
         group_number
       }"}
    end
  end

  defp get_all_operators_in_or_after_group(%{
         round_id: round_id,
         process_id: process_id,
         group_number: group_number
       }) do
    Repo.all(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number >= ^group_number,
        order_by: [asc: [e.group_number, e.rank]]
    )
  end

  # Generate vacation distributions for all specified employees.  Returns an
  # Enumerable (really, a Stream) of unique distributions. If we only want
  # one distribution (general case), then we can use Enum.take/2 to get the
  # first one. If we want to see all the options, we can use the entire stream.
  @spec generate_distributions(
          Draft.BidRound.t(),
          [calculated_employee_quota()],
          acc_vacation_distributions(),
          :ets.tid()
        ) :: Enumerable.t()
  defp generate_distributions(
         round,
         employees,
         acc_vacation_to_distribute,
         memo
       )

  # Base case: No employees to distribute to - return the accumulated list of distributions.
  defp generate_distributions(_round, [], acc_vacation_to_distribute, _memo) do
    [distributions_from_acc_vacation(acc_vacation_to_distribute)]
  end

  # Base case: nothing to distribute to first employee (empty quota), recurse
  # on all remaining employees
  defp generate_distributions(
         round,
         [%{remaining_quota: 0} | remaining_employees],
         acc_vacation_to_distribute,
         memo
       ) do
    generate_distributions(
      round,
      remaining_employees,
      acc_vacation_to_distribute,
      memo
    )
  end

  # Normal case: For each possible vacation distribution for the first
  # employee, try to assign it to them and then recurse with the remaining
  # employees. If we've already tried to assign a given set of assignments to
  # an employee, don't bother trying again: either it worked the first time
  # (and it's present in another assignment ordering) or it doesn't work (and
  # it's not worth trying again).
  defp generate_distributions(
         round,
         [first_employee | remaining_employees],
         acc_vacation_to_distribute,
         memo
       ) do
    counts = count_by_start_date(acc_vacation_to_distribute)
    possible_assignments = all_vacation_available_to_employee(first_employee, :week, counts)
    # Check if we've already calculated a version of these possible
    # assignments, along with the counts of assignments made to days. If we
    # have, then we don't need to do it again.
    key = {first_employee.employee_id, counts}
    hashed_key = :erlang.phash2(key)
    cond do
      :ets.member(memo, hashed_key) ->
        []
      possible_assignments == [] ->
        :ets.insert(memo, {hashed_key})
        []
      true ->
        :ets.insert(memo, {hashed_key})
        possible_assignment_permutations =
          permutations_take(possible_assignments, first_employee.remaining_quota)

        Stream.flat_map(possible_assignment_permutations, fn assignments ->
          acc = Enum.reduce(assignments, acc_vacation_to_distribute, &add_distribution_to_acc/2)

          generate_distributions(round, remaining_employees, acc, memo)
        end)
    end
  end

  @spec add_distribution_to_acc(VacationDistribution.t(), acc_vacation_distributions()) ::
          acc_vacation_distributions()
  defp add_distribution_to_acc(new_distribution, acc_vacation_to_distribute) do
    start_date = new_distribution.start_date

    case acc_vacation_to_distribute do
      %{^start_date => all_assignments_for_date} ->
        %{
          acc_vacation_to_distribute
          | start_date => MapSet.put(all_assignments_for_date, new_distribution)
        }

      map ->
        Map.put(map, start_date, MapSet.new([new_distribution]))
    end
  end

  @spec calculated_quota(
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          Draft.IntervalTypeEnum.t()
        ) :: calculated_employee_quota()
  # Get the given employee's vacation quota for the specified interval type. This currently only
  # returns information about their whole-unit quota (no partial) In the future it could contain
  # information about their minimum quota and maximum desired quota
  # (a preference that is user-set).
  defp calculated_quota(round, employee, :week) do
    balance =
      Repo.one!(
        from q in Draft.EmployeeVacationQuota,
          where:
            q.employee_id == ^employee.employee_id and
              (q.interval_start_date <= ^round.rating_period_start_date and
                 q.interval_end_date >= ^round.rating_period_end_date)
      )

    max_minutes = balance.maximum_minutes

    num_hours_per_day = Draft.JobClassHelpers.num_hours_per_day(employee.job_class)

    # Cap weeks by the maximum number of paid vacation minutes an operator has remaining
    max_weeks = min(div(max_minutes, 60 * num_hours_per_day * 5), balance.weekly_quota)
    available_quota = Draft.DivisionVacationWeekQuota.available_quota(round, employee)

    %{
      employee_id: employee.employee_id,
      job_class: employee.job_class,
      remaining_quota: max_weeks,
      available_quota: available_quota
    }
  end

  @spec all_vacation_available_to_employee(
          calculated_employee_quota(),
          Draft.IntervalTypeEnum.t(),
          %{
            Date.t() => integer()
          }
        ) :: [VacationDistribution.t()]
  # Get all vacation available to the given employee,
  # Based on what is available in their division quota & the distributions not reflected in quota,
  # and vacations they have previously selected. The returned list of vacation distributions
  # Will be ordered from most preferrable to least preferrable.
  # (the latest possible vacation will be first in the list)
  defp all_vacation_available_to_employee(
         employee,
         :week = interval_type,
         distributions_not_reflected_in_quota
       ) do
    employee.available_quota
    |> Enum.map(fn original_quota ->
      %DivisionVacationWeekQuota{
        original_quota
        | quota:
            original_quota.quota -
              Map.get(distributions_not_reflected_in_quota, original_quota.start_date, 0)
      }
    end)
    |> Enum.filter(fn q -> q.quota > 0 end)
    |> Enum.map(fn q ->
      %VacationDistribution{
        employee_id: employee.employee_id,
        interval_type: interval_type,
        start_date: q.start_date,
        end_date: q.end_date
      }
    end)
  end

  @spec count_by_start_date(acc_vacation_distributions()) :: %{Date.t() => integer()}
  defp count_by_start_date(acc_vacation_to_distriubte) do
    Map.new(acc_vacation_to_distriubte, fn {start_date, distributions} ->
      {start_date, MapSet.size(distributions)}
    end)
  end

  @spec distributions_from_acc_vacation(acc_vacation_distributions()) :: [
          VacationDistribution.t()
        ]
  defp distributions_from_acc_vacation(acc_vacation_to_distribute) do
    Enum.flat_map(acc_vacation_to_distribute, fn {_start_date, distributions} ->
      distributions
    end)
  end

  @spec permutations_take(list(), non_neg_integer()) :: Enumerable.t()
  @doc """
  Returns an Enumerable of each permutation of a given list (keeping order) of length n.
  """
  def permutations_take(list, n)

  def permutations_take(list, 0) when is_list(list) do
    []
  end

  def permutations_take([], n) when is_integer(n) and n >= 0 do
    []
  end

  def permutations_take(list, 1) when is_list(list) do
    Enum.map(list, &[&1])
  end

  def permutations_take([first | rest], n) when is_integer(n) and n > 1 do
    with_first = Stream.map(permutations_take(rest, n - 1), &[first | &1])
    without_first = permutations_take(rest, n)
    Stream.concat(with_first, without_first)
  end

  @spec take_result(Enumerable.t(), evaluation_strategy) ::
          {:ok, [VacationDistribution.t()]} | {:error, any()}
  defp take_result(dists, evaluation_strategy) do
    list =
      case evaluation_strategy do
        :evaluate_until_first_solution_found ->
          Enum.take(dists, 1)

        :evaluate_all_possible_solutions ->
          # iterate over the entire stream, but only keep the first option (if any)
          reduce_keeping_first(dists)
      end

    case list do
      [solution] ->
        {:ok, solution}

      _no_solution ->
        {:error, :no_possible_assignments_remaining}
    end
  end

  @spec reduce_keeping_first(Enumerable.t()) :: [any()] | []
  defp reduce_keeping_first(enum) do
    Enum.reduce(enum, [], fn solution, acc ->
      if acc == [] do
        # haven't see a solution yet, keep the current one
        [solution]
      else
        # already have a solution, don't need to keep track of any others
        acc
      end
    end)
  end
end

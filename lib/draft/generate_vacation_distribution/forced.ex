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

  @type gregorian_date :: pos_integer()
  @type acc_vacation_distributions() ::
          {%{gregorian_date() => pos_integer()}, [VacationDistribution.t()]}

  @type calculated_employee_quota() :: %{
          remaining_quota: integer(),
          available_quota: [
            %{
              start_date: gregorian_date(),
              quota: non_neg_integer(),
              distribution: VacationDistribution.t()
            }
          ],
          employee_id: String.t()
        }

  @spec generate_for_group(%{
          round_id: String.t(),
          process_id: String.t(),
          group_number: integer()
        }) :: {:ok, [VacationDistribution.t()]} | :error
  @doc """
  Generate vacation assignments that force all employees in the given group (and all remaining
  groups after them) to use all of their remaining full vacation weeks. Assignments are made in
  seniority order, so the most senior operator is awarded vacation as long as it is possible
  force all remaining operators to use all their vacation time.
  """
  def generate_for_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
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

      acc = {%{}, []}
      memo = :ets.new(:memo, [:bag, :private])
      result = generate_distributions(employee_quotas, acc, memo)

      Logger.info("Finishing Distribution generation: #{inspect(DateTime.utc_now())}")
      # ensure we clean up the ETS table
      :ets.delete(memo)

      if result do
        {:ok, result}
      else
        :error
      end
    else
      Logger.error(
        "No group found with round_id: #{round_id}, process_id: #{process_id}, group_number: #{
          group_number
        }"
      )

      :error
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

  # Generate vacation distributions for all specified employees. For each
  # employee, generate possible permutations of their vacation, assign each
  # permutation and then recurse with the remaining employees. In addition,
  # we keep track of each employee/vacation count we've seen in an ETS table:
  # once we've seen a value we don't need to try it again.
  @spec generate_distributions(
          [calculated_employee_quota()],
          acc_vacation_distributions(),
          :ets.tid()
        ) :: [VacationDistribution.t()] | nil
  defp generate_distributions(
         employees,
         acc_vacation_to_distribute,
         memo
       )

  # Base case: No employees to distribute to - return the accumulated list of distributions.
  defp generate_distributions([], acc_vacation_to_distribute, _memo) do
    acc_vacation_to_distribute
    |> distributions_from_acc_vacation()
    |> Enum.sort_by(&{Date.to_erl(&1.start_date), &1.employee_id})
  end

  # Base case: nothing to distribute to first employee (empty quota), recurse
  # on all remaining employees
  defp generate_distributions(
         [%{remaining_quota: 0} | remaining_employees],
         acc_vacation_to_distribute,
         memo
       ) do
    generate_distributions(
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
         [first_employee | remaining_employees],
         acc_vacation_to_distribute,
         memo
       ) do
    counts = count_by_start_date(acc_vacation_to_distribute)
    possible_assignments = all_vacation_available_to_employee(first_employee, counts)
    # Check if we've already calculated a version of these possible
    # assignments, along with the counts of assignments made to days. If we
    # have, then we don't need to do it again.
    hashed_key = :erlang.phash2({first_employee.employee_id, counts})

    cond do
      :ets.member(memo, hashed_key) ->
        nil

      possible_assignments == [] ->
        :ets.insert(memo, {hashed_key})
        nil

      true ->
        :ets.insert(memo, {hashed_key})

        possible_assignment_permutations =
          permutations_take(
            possible_assignments,
            first_employee.remaining_quota,
            acc_vacation_to_distribute,
            &add_distribution_to_acc/2
          )

        Enum.find_value(possible_assignment_permutations, nil, fn acc ->
          generate_distributions(remaining_employees, acc, memo)
        end)
    end
  end

  @compile {:inline, add_distribution_to_acc: 2}
  @spec add_distribution_to_acc(VacationDistribution.t(), acc_vacation_distributions()) ::
          acc_vacation_distributions()
  defp add_distribution_to_acc(new_distribution, {counts, distributions}) do
    start_date = new_distribution.start_date

    new_count =
      case counts do
        %{^start_date => x} -> x + 1
        _counts -> 1
      end

    counts = Map.put(counts, start_date, new_count)

    {counts, [new_distribution | distributions]}
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
  defp calculated_quota(round, employee, :week = interval_type) do
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
    available_quota = DivisionVacationWeekQuota.available_quota(round, employee)

    %{
      employee_id: employee.employee_id,
      # job_class: employee.job_class,
      remaining_quota: max_weeks,
      available_quota:
        Enum.map(available_quota, fn q ->
          %{
            start_date: Date.to_gregorian_days(q.start_date),
            quota: q.quota,
            distribution: %VacationDistribution{
              employee_id: employee.employee_id,
              interval_type: interval_type,
              start_date: q.start_date,
              end_date: q.end_date
            }
          }
        end)
    }
  end

  @compile {:inline, all_vacation_available_to_employee: 2}
  @spec all_vacation_available_to_employee(
          calculated_employee_quota(),
          %{
            gregorian_date() => integer()
          }
        ) :: [VacationDistribution.t()]
  # Get all vacation available to the given employee,
  # Based on what is available in their division quota & the distributions not reflected in quota,
  # and vacations they have previously selected. The returned list of vacation distributions
  # Will be ordered from most preferrable to least preferrable.
  # (the latest possible vacation will be first in the list)
  defp all_vacation_available_to_employee(
         employee,
         distributions_not_reflected_in_quota
       ) do
    :lists.filter(
      fn %{start_date: start_date, quota: quota} ->
        case distributions_not_reflected_in_quota do
          %{^start_date => extra_vacation} -> quota > extra_vacation
          _distributions -> true
        end
      end,
      employee.available_quota
    )
  end

  @compile {:inline, count_by_start_date: 1}
  @spec count_by_start_date(acc_vacation_distributions()) :: %{gregorian_date() => integer()}
  defp count_by_start_date({counts, _distributions}) do
    counts
  end

  @spec distributions_from_acc_vacation(acc_vacation_distributions()) :: [
          VacationDistribution.t()
        ]
  defp distributions_from_acc_vacation({_counts, distributions}) do
    Enum.map(distributions, & &1.distribution)
  end

  @spec permutations_take(list(), non_neg_integer(), acc, (any(), acc -> acc)) ::
          Enumerable.t()
        when acc: any()

  @doc """
  Returns an Enumerable of each permutation of a given list of length n.

  To create the return value, a function is called with the item and an
  accumulator, returning the accumulator.
  """
  def permutations_take(list, n, acc, fun)

  def permutations_take(list, 0, _acc, fun) when is_list(list) and is_function(fun, 2) do
    []
  end

  def permutations_take([], n, _acc, fun) when is_integer(n) and n >= 0 and is_function(fun, 2) do
    []
  end

  def permutations_take([first | rest], n, acc, fun)
      when is_integer(n) and n > 1 and is_function(fun, 2) do
    acc_with_first = fun.(first, acc)
    with_first = permutations_take(rest, n - 1, acc_with_first, fun)
    without_first = permutations_take(rest, n, acc, fun)
    Stream.concat(with_first, without_first)
  end

  def permutations_take(list, 1, acc, fun) when is_list(list) and is_function(fun, 2) do
    :lists.map(fn x -> fun.(x, acc) end, list)
  end
end

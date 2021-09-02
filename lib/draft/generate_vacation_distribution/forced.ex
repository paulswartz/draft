defmodule Draft.GenerateVacationDistribution.Forced do
  @moduledoc """
  Generate a list of vacation weeks that can be assigned to all employees in the given group,
  ensuring that it will be possible to force all remaining employees to take vacation as well.
  """
  alias Draft.DivisionQuota
  alias Draft.VacationDistribution
  require Logger

  @type gregorian_date() :: pos_integer()
  @type available_quota() :: {gregorian_date(), non_neg_integer(), VacationDistribution.t()}
  @type acc_vacation_distributions() ::
          {%{gregorian_date() => pos_integer()}, [VacationDistribution.t()]}

  @type calculated_employee_quota() :: %{
          amount_to_force: integer(),
          available_quota: [available_quota()],
          employee_id: String.t()
        }

  @spec generate_for_employees(Draft.BidSession.t(), [{String.t(), pos_integer()}], [
          VacationDistribution.t()
        ]) ::
          {:ok, [VacationDistribution.t()]} | :error
  @doc """
  Generate vacation assignments that force all employees in the given group (and all remaining
  groups after them) to use all of their remaining full vacation weeks. Assignments are made in
  seniority order, so the most senior operator is awarded vacation as long as it is possible
  force all remaining operators to use all their vacation time.
  """
  def generate_for_employees(
        session,
        employees_to_force,
        previous_distributions
      ) do
    Logger.info("Starting vacation forcing for round
        #{session.round_id}-#{session.process_id}: #{inspect(DateTime.utc_now())}")

    employees = Enum.map(employees_to_force, &calculated_quota(session, &1))

    acc =
      previous_distributions
      |> Enum.frequencies_by(&Date.to_gregorian_days(&1.start_date))
      |> (&{&1, previous_distributions}).()

    memo = :ets.new(:memo, [:bag, :private])
    result = generate_distributions(employees, acc, memo)

    Logger.info("Finishing vacation forcing for round
        #{session.round_id}-#{session.process_id}:#{inspect(DateTime.utc_now())}")
    # ensure we clean up the ETS table
    :ets.delete(memo)

    if result do
      {:ok, result}
    else
      :error
    end
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
         [%{amount_to_force: 0} | remaining_employees],
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
    %{employee_id: employee_id, amount_to_force: amount_to_force} = first_employee
    counts = count_by_start_date(acc_vacation_to_distribute)
    # Check if we've already calculated a version of these possible
    # assignments, along with the counts of assignments made to days. If we
    # have, then we don't need to do it again.
    hashed_key = :erlang.phash2({employee_id, counts})

    if :ets.member(memo, hashed_key) do
      nil
    else
      :ets.insert(memo, {hashed_key})
      possible_assignments = all_vacation_all_available_quota_ranked(first_employee, counts)

      possible_assignment_permutations =
        permutations_take(
          possible_assignments,
          amount_to_force,
          acc_vacation_to_distribute,
          &add_distribution_to_acc/2
        )

      case possible_assignment_permutations do
        [] ->
          nil

        [acc] ->
          # only one possibility
          generate_distributions(remaining_employees, acc, memo)

        possible_assignment_permutations ->
          Enum.find_value(possible_assignment_permutations, nil, fn acc ->
            generate_distributions(remaining_employees, acc, memo)
          end)
      end
    end
  end

  @compile {:inline, add_distribution_to_acc: 2}
  @spec add_distribution_to_acc(
          available_quota(),
          acc_vacation_distributions()
        ) ::
          acc_vacation_distributions()
  defp add_distribution_to_acc(available_quota, {counts, distributions}) do
    {start_date, _quota, distribution} = available_quota

    new_count =
      case counts do
        %{^start_date => x} -> x + 1
        _counts -> 1
      end

    counts = Map.put(counts, start_date, new_count)

    {counts, [distribution | distributions]}
  end

  @spec calculated_quota(
          Draft.BidSession.t(),
          {String.t(), pos_integer()}
        ) :: calculated_employee_quota()
  # Get the employee with all possible vacation distributions they could be awarded.
  defp calculated_quota(session, {employee_id, amount_to_force}) do
    available_quota =
      DivisionQuota.all_available_quota_ranked(
        session,
        employee_id
      )

    %{
      employee_id: employee_id,
      amount_to_force: amount_to_force,
      available_quota:
        Enum.map(available_quota, fn q ->
          {
            Date.to_gregorian_days(q.start_date),
            q.quota,
            %VacationDistribution{
              employee_id: employee_id,
              interval_type: session.type_allowed,
              start_date: q.start_date,
              end_date: q.end_date,
              is_forced: true,
              preference_rank: q.preference_rank
            }
          }
        end)
    }
  end

  @compile {:inline, all_vacation_all_available_quota_ranked: 2}
  @spec all_vacation_all_available_quota_ranked(
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
  defp all_vacation_all_available_quota_ranked(
         employee,
         distributions_not_reflected_in_quota
       ) do
    :lists.filter(
      fn {start_date, quota, _distribution} ->
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
    distributions
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
      when is_list(list) and is_integer(n) and n >= 0 and is_function(fun, 2) do
    l = length(list)
    permutations_take_internal(list, l, n, acc, fun)
  end

  defp permutations_take_internal([first | rest], l, n, acc, fun) when n > 1 and l > n do
    acc_with_first = fun.(first, acc)
    with_first = permutations_take_internal(rest, l - 1, n - 1, acc_with_first, fun)

    if with_first == [] do
      []
    else
      without_first = permutations_take_internal(rest, l - 1, n, acc, fun)

      if without_first == [] do
        with_first
      else
        Stream.concat(with_first, without_first)
      end
    end
  end

  defp permutations_take_internal(list, _l, 1, acc, fun) do
    # permutations of length 1 is taking each item
    :lists.map(&fun.(&1, acc), list)
  end

  defp permutations_take_internal(list, l, l, acc, fun) do
    # only permutation is taking each item
    [:lists.foldl(fun, acc, list)]
  end

  defp permutations_take_internal(_list, _l, _n, _acc, _fun) do
    []
  end
end

defmodule Draft.DivisionQuota do
  @moduledoc """
  Represents vacation quota as ranked by a particular employee
  """

  @type employee_ranked_quota :: %{
          start_date: Date.t(),
          end_date: Date.t(),
          interval_type: Draft.IntervalType.t(),
          quota: non_neg_integer(),
          preference_rank: pos_integer() | nil,
          employee_id: String.t()
        }

  @doc """
  Get all vacation intervals that is available for the given employee, based on their job class,
  the available quota for their division, and their previously selected vacation time.
  Available intervals are returned sorted first based on their latest preferences, so their most
  preferred vacation would be first. Any available vacation that the employee has not marked as a
  preference will be returned sorted by descending start date (latest date first)
  """

  @spec available_with_employee_rank(
          Draft.BidSession.t(),
          %{:employee_id => String.t(), :job_class => String.t(), optional(atom()) => any()}
        ) :: [employee_ranked_quota()]
  def available_with_employee_rank(session, employee) do
    available_quota = available_quota(session, employee)

    employee_preferences =
      Draft.EmployeeVacationPreferenceSet.latest_preferences(
        session.process_id,
        session.round_id,
        employee.employee_id,
        session.type_allowed
      )

    rank_vacations(employee.employee_id, available_quota, employee_preferences)
  end

  defp available_quota(%{type_allowed: :week} = session, employee) do
    session
    |> Draft.DivisionVacationWeekQuota.available_quota(employee)
    |> Enum.map(
      &%{
        start_date: &1.start_date,
        end_date: &1.end_date,
        quota: &1.quota,
        employee_id: employee.employee_id,
        interval_type: session.type_allowed
      }
    )
  end

  defp available_quota(%{type_allowed: :day} = session, employee) do
    session
    |> Draft.DivisionVacationDayQuota.available_quota(employee)
    |> Enum.map(
      &%{
        start_date: &1.date,
        end_date: &1.date,
        quota: &1.quota,
        employee_id: employee.employee_id,
        interval_type: session.type_allowed
      }
    )
  end

  @spec rank_vacations(String.t(), [employee_ranked_quota()], %{Date.t() => pos_integer()}) :: [
          employee_ranked_quota()
        ]
  defp rank_vacations(employee_id, vacations, employee_preferences) do
    vacations
    |> Enum.map(fn vacation_quota ->
      Map.merge(vacation_quota, %{
        preference_rank: Map.get(employee_preferences, vacation_quota.start_date),
        employee_id: employee_id
      })
    end)
    |> Enum.sort(&compare_ranked_quota(&1, &2))
  end

  # Return true if vac1 should preceed  vac2, otherwise false.
  defp compare_ranked_quota(vac1, vac2)

  defp compare_ranked_quota(%{preference_rank: preference_rank1}, %{
         preference_rank: preference_rank2
       })
       when preference_rank1 < preference_rank2 do
    true
  end

  defp compare_ranked_quota(
         %{preference_rank: preference_rank1, start_date: start_date_1},
         %{preference_rank: preference_rank2, start_date: start_date_2}
       )
       when preference_rank1 == preference_rank2 do
    # if start_date_1 > start_date_2, start_date_1 should precede start_date_2 to achieve
    # descending sort
    Date.compare(start_date_1, start_date_2) == :gt
  end

  defp compare_ranked_quota(%{preference_rank: preference_rank1}, %{
         preference_rank: preference_rank2
       })
       when preference_rank1 > preference_rank2 do
    false
  end
end

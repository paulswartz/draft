defmodule Draft.EmployeeVacationQuotaSummary do
  @moduledoc """
    Common representation of employee vacation in minutes.
  """

  defstruct [
    :employee_id,
    :job_class,
    :group_number,
    :rank,
    :interval_type,
    :total_available_minutes,
    :anniversary_date,
    :minutes_only_available_as_of_anniversary
  ]

  @type t :: %__MODULE__{
          employee_id: String.t(),
          job_class: String.t(),
          group_number: integer(),
          rank: integer(),
          interval_type: Draft.IntervalType.t(),
          total_available_minutes: integer(),
          anniversary_date: Date.t() | nil,
          minutes_only_available_as_of_anniversary: integer()
        }

  @spec get(Draft.EmployeeRanking.t(), Date.t(), Date.t(), Draft.IntervalType.t()) :: t()
  @doc """
  Get a quota summary for the given employee that covers the given date range.
  """
  def get(employee_ranking, start_date, end_date, interval_type) do
    quota =
      Draft.EmployeeVacationQuota.quota_covering_interval(
        employee_ranking.employee_id,
        start_date,
        end_date
      )

    {total_interval_quota, anniversary_quota} =
      case interval_type do
        :week -> {quota.weekly_quota, quota.available_after_weekly_quota || 0}
        :day -> {quota.dated_quota, quota.available_after_dated_quota || 0}
      end

    existing_vacations = existing_vacation_counts(quota, employee_ranking.job_class)

    # total used minutes across weeks and days
    used_minutes = existing_vacations |> Map.values() |> Enum.map(&elem(&1, 2)) |> Enum.sum()

    # count of used weeks or days (whichever we're currently checking), and
    # how many minutes that represents
    {used_interval, minutes_per_interval, _} = Map.fetch!(existing_vacations, interval_type)

    remaining_interval = subtract_quota(total_interval_quota, used_interval)

    # total remaining is the lesser of 1) remaining interval * minutes per
    # interval or 2) maximum minutes - used minutes (across all intervals)
    total_available_minutes =
      min(remaining_interval * minutes_per_interval, quota.maximum_minutes - used_minutes)

    %__MODULE__{
      employee_id: employee_ranking.employee_id,
      job_class: employee_ranking.job_class,
      group_number: employee_ranking.group_number,
      rank: employee_ranking.rank,
      interval_type: interval_type,
      total_available_minutes: total_available_minutes,
      anniversary_date: quota.available_after_date,
      minutes_only_available_as_of_anniversary: anniversary_quota * minutes_per_interval
    }
  end

  @spec existing_vacation_counts(Draft.EmployeeVacationQuota.t(), String.t()) :: %{
          week: {quota, minutes_per_interval, minutes},
          day: {quota, minutes_per_interval, minutes}
        }
        when quota: non_neg_integer(),
             minutes_per_interval: pos_integer(),
             minutes: non_neg_integer()
  defp existing_vacation_counts(
         %{
           employee_id: employee_id,
           interval_end_date: date
         },
         job_class
       ) do
    # look at the full year for vacation. ideally we would get these dates as part
    # of some record, but we don't currently. -ps
    start_of_year = %{date | month: 1, day: 1}
    end_of_year = %{date | month: 12, day: 31}

    Map.new([:week, :day], fn interval_type ->
      existing_vacation =
        Draft.EmployeeVacationSelection.assigned_vacation_count(
          employee_id,
          start_of_year,
          end_of_year,
          interval_type
        )

      minutes_per_interval = default_minutes_per_interval(job_class, interval_type)

      {interval_type,
       {existing_vacation, minutes_per_interval, existing_vacation * minutes_per_interval}}
    end)
  end

  @doc """
  Get the number of minutes available as of a given date, based on whether or not the
  anniversary date has passed.
  """
  @spec minutes_available_as_of_date(t(), Date.t()) :: integer()
  def minutes_available_as_of_date(%{anniversary_date: nil} = quota_summary, _as_of_date) do
    quota_summary.total_available_minutes
  end

  def minutes_available_as_of_date(quota_summary, as_of_date) do
    case Date.compare(quota_summary.anniversary_date, as_of_date) do
      :gt ->
        max(
          quota_summary.total_available_minutes -
            quota_summary.minutes_only_available_as_of_anniversary,
          0
        )

      _lt_or_eq ->
        quota_summary.total_available_minutes
    end
  end

  defp default_minutes_per_interval(job_class, :week) do
    Draft.JobClassHelpers.num_hours_per_week(job_class) * 60
  end

  defp default_minutes_per_interval(job_class, :day) do
    Draft.JobClassHelpers.num_hours_per_day(job_class, :five_two) * 60
  end

  @spec subtract_quota(integer(), integer()) :: non_neg_integer()
  @doc """
  Subtracts a given amount from a quota, without going below 0.

  The vacation quotas given by HASTUS (weekly_quota, dated_quota) include any weeks / days that are only available on and after an anniversary date.
  This function returns the initial quota less the quota given to subtract. The lowest possible quota returned is zero; quota cannot be negative.

  iex> EmployeeVacationQuotaSummary.subtract_quota(6, 1)
  5

  iex> EmployeeVacationQuotaSummary.subtract_quota(0, 1)
  0

  iex> EmployeeVacationQuotaSummary.subtract_quota(5, 5)
  0
  """
  def subtract_quota(initial_quota, quota_to_subtract) do
    max(initial_quota - quota_to_subtract, 0)
  end
end

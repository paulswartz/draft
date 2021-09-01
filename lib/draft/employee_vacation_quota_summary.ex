defmodule Draft.EmployeeVacationQuotaSummary do
  @moduledoc """
    Common representation of employee vacation in minutes.
  """

  defstruct [
    :employee_id,
    :job_class,
    :interval_type,
    :total_available_minutes,
    :anniversary_date,
    :minutes_only_available_as_of_anniversary
  ]

  @type t :: %__MODULE__{
          employee_id: String.t(),
          job_class: String.t(),
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

    %__MODULE__{
      employee_id: employee_ranking.employee_id,
      job_class: employee_ranking.job_class,
      interval_type: interval_type,
      total_available_minutes:
        min(
          total_interval_quota *
            default_minutes_per_interval(employee_ranking.job_class, interval_type),
          quota.maximum_minutes
        ),
      anniversary_date: quota.available_after_date,
      minutes_only_available_as_of_anniversary:
        anniversary_quota *
          default_minutes_per_interval(employee_ranking.job_class, interval_type)
    }
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
end

defmodule Draft.JobClassHelpers do
  @moduledoc """
  Helper functions for interpreting job class data
  """

  @full_time_vacation_group "FTVacQuota"
  @part_time_vacation_group "PTVacQuota"

  @job_class_to_selection_set %{
    "000100" => @full_time_vacation_group,
    "000300" => @full_time_vacation_group,
    "000800" => @full_time_vacation_group,
    "001100" => @part_time_vacation_group,
    "000200" => @part_time_vacation_group,
    "000900" => @part_time_vacation_group
  }

  @spec get_selection_set(String.t()) :: String.t()
  @doc """
  Get the vacation selection set identifier for the givne job class
  """
  def get_selection_set(job_class) do
    @job_class_to_selection_set[job_class]
  end

  @spec pt_or_ft(String.t()) :: :ft | :pt
  @doc """
  Determine if the given job class is categorized as part time or full time
  """
  def pt_or_ft(job_class) do
    case @job_class_to_selection_set[job_class] do
      @full_time_vacation_group -> :ft
      @part_time_vacation_group -> :pt
    end
  end

  @spec num_hours_per_day(String.t(), Draft.WorkOffRatio.t()) :: integer()
  @doc """
  The number of hours that are worked in a day.
  """
  def num_hours_per_day(job_class, work_off_ratio) do
    case {pt_or_ft(job_class), work_off_ratio} do
      {:ft, :five_two} -> 8
      {:ft, :four_three} -> 10
      {:pt, :five_two} -> 6
    end
  end

  @doc """
  The number of hours that are worked in a week
  """
  @spec num_hours_per_week(String.t()) :: number()
  def num_hours_per_week(job_class) do
    case pt_or_ft(job_class) do
      :pt -> 30
      :ft -> 40
    end
  end
end

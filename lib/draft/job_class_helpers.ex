defmodule Draft.JobClassHelpers do
  @moduledoc """
  Helper functions for interpreting job class data
  """

  @job_class_to_selection_set %{
    "000100" => :ft,
    "000300" => :ft,
    "000800" => :ft,
    "001100" => :pt,
    "000200" => :pt,
    "000900" => :pt
  }

  @spec job_category_for_class(String.t()) :: Draft.JobClassCategory.t()
  @doc """
  Get the vacation selection set identifier for the givne job class
  """
  def job_category_for_class(job_class) do
    @job_class_to_selection_set[job_class]
  end

  @spec job_classes_in_category(Draft.JobClassCategory.t()) :: Enumerable.t()
  @doc """
  Get the job classes which meet a given selection set identifier.
  """
  def job_classes_in_category(selection_set) do
    for {job_class, ^selection_set} <- @job_class_to_selection_set do
      job_class
    end
  end

  @spec num_hours_per_day(String.t(), Draft.WorkOffRatio.t()) :: integer()
  @doc """
  The number of hours that are worked in a day.
  """
  def num_hours_per_day(job_class, work_off_ratio) do
    case {job_category_for_class(job_class), work_off_ratio} do
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
    case job_category_for_class(job_class) do
      :pt -> 30
      :ft -> 40
    end
  end

  @spec weeks_from_minutes(non_neg_integer(), String.t()) :: non_neg_integer()
  @doc """
  The number of weeks that is equivalent to the number of minutes given for a job class, rounded down to the nearest whole week.

  iex> Draft.JobClassHelpers.weeks_from_minutes(7200, "000100")
  3
  iex> Draft.JobClassHelpers.weeks_from_minutes(7300, "000100")
  3
  iex> Draft.JobClassHelpers.weeks_from_minutes(7200, "001100")
  4
  """
  def weeks_from_minutes(minutes, job_class) do
    div(minutes, num_hours_per_week(job_class) * 60)
  end
end

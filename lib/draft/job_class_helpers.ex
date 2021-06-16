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
end

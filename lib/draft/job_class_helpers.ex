defmodule Draft.JobClassHelpers do
  def get_selection_set(job_type) do
    full_time = "FTVacQuota"
    part_time = "PTVacQuota"

    job_class_map = %{
      "000100" => full_time,
      "000300" => full_time,
      "000800" => full_time,
      "001100" => part_time,
      "000200" => part_time,
      "000900" => part_time
    }

    job_class_map[job_type]
  end
end

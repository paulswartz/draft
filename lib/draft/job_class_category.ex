defmodule Draft.JobClassCategory do
  @moduledoc """
  Represent categories of job classes -- part-time and full-time
  """
  use EctoEnum, pt: "pt", ft: "ft"

  @spec from_hastus_division_quota(String.t()) :: t()
  @doc """
  Return the appropriate job category based on the selection set in the divison quota file.
  """
  def from_hastus_division_quota("FTVacQuota") do
    :ft
  end

  def from_hastus_division_quota("PTVacQuota") do
    :pt
  end
end

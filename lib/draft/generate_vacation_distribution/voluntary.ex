defmodule Draft.GenerateVacationDistribution.Voluntary do
  @moduledoc """
  Defines contract for generating vacation distributions for employees voluntarily taking
  vacation time.
  """

  alias Draft.GenerateVacationDistribution.Days
  alias Draft.GenerateVacationDistribution.Weeks

  @callback generate(
              integer(),
              Draft.BidRound.t(),
              Draft.EmployeeRanking.t(),
              integer(),
              nil | %{anniversary_date: Date.t(), anniversary_weeks: number()}
            ) :: [Draft.VacationDistribution.t()]

  @spec generate(
          integer(),
          Draft.BidRound.t(),
          Draft.EmployeeRanking.t(),
          integer(),
          nil | %{anniversary_date: Date.t(), anniversary_weeks: number()},
          Draft.IntervalType.t()
        ) :: [Draft.VacationDistribution.t()]
  @doc """
  Generate a list of vacations to distribute to the employee voluntarily taking vacation.
  """
  def generate(
        distribution_run_id,
        round,
        employee,
        max_quota,
        anniversary_vacation,
        interval_type
      )

  def generate(
        distribution_run_id,
        round,
        employee,
        max_quota,
        anniversary_vacation,
        :week
      ) do
    Weeks.generate(
      distribution_run_id,
      round,
      employee,
      max_quota,
      anniversary_vacation
    )
  end

  def generate(
        distribution_run_id,
        round,
        employee,
        max_quota,
        anniversary_vacation,
        :day
      ) do
    Days.generate(
      distribution_run_id,
      round,
      employee,
      max_quota,
      anniversary_vacation
    )
  end
end

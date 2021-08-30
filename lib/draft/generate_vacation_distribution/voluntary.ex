defmodule Draft.GenerateVacationDistribution.Voluntary do
  @moduledoc """
  Defines contract for generating vacation distributions for employees voluntarily taking
  vacation time.
  """

  alias Draft.GenerateVacationDistribution.Days
  alias Draft.GenerateVacationDistribution.Weeks

  @callback generate(
              Draft.VacationDistributionRun.id(),
              Draft.BidSession.t(),
              Draft.EmployeeVacationQuotaSummary.t()
            ) :: [Draft.VacationDistribution.t()]

  @spec generate(
          Draft.VacationDistributionRun.id(),
          Draft.BidSession.t(),
          Draft.EmployeeVacationQuotaSummary.t()
        ) :: [Draft.VacationDistribution.t()]
  @doc """
  Generate a list of vacations to distribute to the employee voluntarily taking vacation.
  """
  def generate(
        distribution_run_id,
        session,
        employee_vacation_quota_summary
      )

  def generate(
        distribution_run_id,
        %{type: :vacation, type_allowed: :week} = session,
        employee_vacation_quota_summary
      ) do
    Weeks.generate(
      distribution_run_id,
      session,
      employee_vacation_quota_summary
    )
  end

  def generate(
        distribution_run_id,
        %{type: :vacation, type_allowed: :day} = session,
        employee_vacation_quota_summary
      ) do
    Days.generate(
      distribution_run_id,
      session,
      employee_vacation_quota_summary
    )
  end
end

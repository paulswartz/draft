defmodule Draft.BasicVacationDistributionTest do
  use ExUnit.Case
  use Draft.DataCase
  alias Draft.BasicVacationDistribution
  alias Draft.EmployeeVacationAssignment


  @vacation_files  [
    {DivisionVacationDayQuota, "../../test/support/test_data/test_vac_div_quota_dated.csv"},
    {DivisionVacationWeekQuota, "../../test/support/test_data/test_vac_div_quota_weekly.csv"},
    {EmployeeVacationSelection, "../../test/support/test_data/test_vac_emp_selections.csv"},
    {EmployeeVacationQuota, "../../test/support/test_data/test_vac_emp_quota.csv"}
  ]

  setup do
    vacation_assignments = BasicVacationDistribution.basic_vacation_distribution(@vacation_files)
    {:ok, vacation_assignments: vacation_assignments}
  end

  describe "basic_vacation_distribution/1" do
    test "Operator with no vacation time left is not assigned vacation", context do
      assert Enum.filter(context[:vacation_assignments], fn x -> x.employee_id == "00002" end) == []
    end

    end
  end

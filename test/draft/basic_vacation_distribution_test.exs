defmodule Draft.BasicVacationDistributionTest do
  use ExUnit.Case
  use Draft.DataCase
  alias Draft.BasicVacationDistribution
  alias Draft.BidRoundSetup
  alias Draft.DivisionVacationDayQuota
  alias Draft.DivisionVacationWeekQuota
  alias Draft.EmployeeVacationAssignment
  alias Draft.EmployeeVacationQuota
  alias Draft.EmployeeVacationSelection

  setup do
    BidRoundSetup.update_bid_round_data(
      "../../test/support/test_data/basic_distribution/test_rounds.csv"
    )

    vacation_assignments =
      BasicVacationDistribution.basic_vacation_distribution([
        {DivisionVacationDayQuota,
         "../../test/support/test_data/basic_distribution/test_vac_div_quota_dated.csv"},
        {DivisionVacationWeekQuota,
         "../../test/support/test_data/basic_distribution/test_vac_div_quota_weekly.csv"},
        {EmployeeVacationSelection,
         "../../test/support/test_data/basic_distribution/test_vac_emp_selections.csv"},
        {EmployeeVacationQuota,
         "../../test/support/test_data/basic_distribution/test_vac_emp_quota.csv"}
      ])

    require Logger
    Logger.info(vacation_assignments)
    {:ok, vacation_assignments: vacation_assignments}
  end

  describe "basic_vacation_distribution/1" do
    test "Earliest week with vacation quota of 0 is never assigned", context do
      assert Enum.filter(context[:vacation_assignments], fn x ->
               x.start_date == "03/21/2021" and x.start_date == "03/27/2021"
             end) == []
    end

    test "Earliest day with vacation quota of 0 is never assigned", context do
      assert Enum.filter(context[:vacation_assignments], fn x ->
               x.start_date == "03/14/2021" and x.end_date == "03/14/2021"
             end) == []
    end

    test "Operator with more than two weeks quota ", context do
      assert Enum.filter(context[:vacation_assignments], fn x ->
               x.start_date == "03/21/2021" and x.start_date == "03/27/2021"
             end) == []
    end

    test "First operator is assigned two weeks", context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00001")

      assert length(vacation_assignments) == 2

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]},
               %EmployeeVacationAssignment{start_date: ~D[2021-04-04], end_date: ~D[2021-04-10]}
             ] = vacation_assignments
    end

    test "Second operator with no vacation time left is not assigned vacation", context do
      assert get_assignments_for_employee(context[:vacation_assignments], "00002") ==
               []
    end

    test "third operator is assigned first four available days", context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00003")

      assert length(vacation_assignments) == 4

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-03-15], end_date: ~D[2021-03-15]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-16], end_date: ~D[2021-03-16]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-17], end_date: ~D[2021-03-17]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-18], end_date: ~D[2021-03-18]}
             ] = vacation_assignments
    end

    test "fourth operator is assigned next available week (not 3/28, which had a quota of 1 and was taken by operator 2)",
         context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00004")

      assert length(vacation_assignments) == 1

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-04-04], end_date: ~D[2021-04-10]}
             ] = vacation_assignments
    end

    test "fifth operator is assigned first four available days (not 3/15, which had a quota of 1 was taken by operator 3)",
         context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00005")

      assert length(vacation_assignments) == 4

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-03-16], end_date: ~D[2021-03-16]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-17], end_date: ~D[2021-03-17]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-18], end_date: ~D[2021-03-18]},
               %EmployeeVacationAssignment{start_date: ~D[2021-03-19], end_date: ~D[2021-03-19]}
             ] = vacation_assignments
    end

    test "sixth operator is assigned one week (not 3/28, which had a quota of 1 and was taken by operator 2)",
         context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00006")

      assert length(vacation_assignments) == 1

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-04-04], end_date: ~D[2021-04-10]}
             ] = vacation_assignments
    end

    test "seventh operator is assigned first day that does not conflict with their previously selected dated vacation",
         context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00007")

      assert length(vacation_assignments) == 1

      assert Repo.get_by!(DivisionVacationDayQuota,
               division_id: "112",
               employee_selection_set: "FTVacQuota",
               date: ~D[2021-03-19]
             ).quota == 1

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-03-20], end_date: ~D[2021-03-20]}
             ] = vacation_assignments
    end

    test "eight operator is assigned first week that does not conflict with their previously selected week vacation",
         context do
      vacation_assignments = get_assignments_for_employee(context[:vacation_assignments], "00008")

      assert length(vacation_assignments) == 1

      assert Repo.get_by!(DivisionVacationWeekQuota,
               division_id: "112",
               employee_selection_set: "FTVacQuota",
               start_date: ~D[2021-04-04],
               end_date: ~D[2021-04-10]
             ).quota == 2

      assert [
               %EmployeeVacationAssignment{start_date: ~D[2021-04-11], end_date: ~D[2021-04-17]}
             ] = vacation_assignments
    end
  end

  defp get_assignments_for_employee(assignments, employee_id) do
    Enum.filter(assignments, fn x ->
      x.employee_id == employee_id
    end)
  end
end

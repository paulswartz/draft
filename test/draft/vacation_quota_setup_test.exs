defmodule Draft.VacationQuotaSetupTest do
  use ExUnit.Case
  use Draft.DataCase
  alias Draft.DivisionVacationQuotaDated
  alias Draft.DivisionVacationQuotaWeek
  alias Draft.EmployeeVacationQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.VacationQuotaSetup

  setup do
    VacationQuotaSetup.update_vacation_quota_data(%{
      DivisionVacationQuotaDated => "../../test/support/test_data/test_vac_div_quota_dated.csv",
      DivisionVacationQuotaWeek => "../../test/support/test_data/test_vac_div_quota_weekly.csv",
      EmployeeVacationSelection => "../../test/support/test_data/test_vac_emp_selections.csv",
      EmployeeVacationQuota => "../../test/support/test_data/test_vac_emp_quota.csv"
    })

    :ok
  end

  describe "update_bid_round_data/1" do
    test "Correct number of records present" do
      all_div_quota_dated = Repo.all(DivisionVacationQuotaDated)
      assert length(all_div_quota_dated) == 12
      all_div_quota_weekly = Repo.all(DivisionVacationQuotaWeek)
      assert length(all_div_quota_weekly) == 14
      all_emp_quota = Repo.all(EmployeeVacationQuota)
      assert length(all_emp_quota) == 28
      all_emp_selections = Repo.all(EmployeeVacationSelection)
      assert length(all_emp_selections) == 6
    end

    test "Dated division vacation quota as expected" do
      date_quota =
        Repo.get_by(DivisionVacationQuotaDated, date: ~D[2021-01-12], division_id: "112")

      assert 12 = date_quota.quota
    end

    test "Weekly division vacation quota as expected" do
      date_quota =
        Repo.get_by(DivisionVacationQuotaWeek,
          start_date: ~D[2021-01-03],
          division_id: "112",
          employee_selection_set: "FTVacQuota"
        )

      assert 1 = date_quota.quota
    end

    test "Employee selected vacation as expected" do
      employee_selected_vacation = Repo.get_by(EmployeeVacationSelection, employee_id: "00001")

      assert ~D[2021-05-23] = employee_selected_vacation.start_date
      assert ~D[2021-05-29] = employee_selected_vacation.end_date
    end

    test "Employee vacation quota as expected" do
      employee_selected_vacation =
        Repo.get_by(EmployeeVacationQuota,
          employee_id: "00001",
          interval_start_date: ~D[2021-04-21]
        )

      assert 3 = employee_selected_vacation.weekly_quota
      assert 5 = employee_selected_vacation.dated_quota
      assert 3519 = employee_selected_vacation.maximum_minutes
    end
  end
end

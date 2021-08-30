defmodule Draft.EmployeeVacationQuotaTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      emp_quota =
        EmployeeVacationQuota.from_parts([
          "00001",
          "01/01/2021",
          "12/31/2021",
          "2",
          "2",
          "5",
          "5",
          nil,
          "06/30/2021",
          "1",
          "5",
          "10h30"
        ])

      assert %EmployeeVacationQuota{
               employee_id: "00001",
               interval_start_date: ~D[2021-01-01],
               interval_end_date: ~D[2021-12-31],
               weekly_quota: 2,
               dated_quota: 5,
               restricted_week_quota: 0,
               available_after_date: ~D[2021-06-30],
               available_after_weekly_quota: 1,
               available_after_dated_quota: 5,
               maximum_minutes: 630
             } = emp_quota
    end
  end

  describe "get_anniversary_quota/1" do
    test "Nil if no anniversary date" do
      assert nil ==
               EmployeeVacationQuota.get_anniversary_quota(%EmployeeVacationQuota{
                 employee_id: "00001",
                 interval_start_date: ~D[2021-01-01],
                 interval_end_date: ~D[2021-12-31],
                 weekly_quota: 2,
                 dated_quota: 5,
                 restricted_week_quota: 0,
                 available_after_date: nil,
                 available_after_weekly_quota: 0,
                 available_after_dated_quota: 0,
                 maximum_minutes: 630
               })
    end

    test "Expected values when anniversary date present" do
      assert %{anniversary_date: ~D[2021-06-30], anniversary_weeks: 1, anniversary_days: 5} ==
               EmployeeVacationQuota.get_anniversary_quota(%EmployeeVacationQuota{
                 employee_id: "00001",
                 interval_start_date: ~D[2021-01-01],
                 interval_end_date: ~D[2021-12-31],
                 weekly_quota: 2,
                 dated_quota: 5,
                 restricted_week_quota: 0,
                 available_after_date: ~D[2021-06-30],
                 available_after_weekly_quota: 1,
                 available_after_dated_quota: 5,
                 maximum_minutes: 630
               })
    end
  end

  describe "adjust_quota/4" do
    test "Initial quota > quota to subtract" do
      assert 5 == EmployeeVacationQuota.adjust_quota(6, 1)
    end

    test "Initial quota < quota to subtract" do
      assert 0 == EmployeeVacationQuota.adjust_quota(0, 1)
    end

    test "Initial quota = quota to subtract" do
      assert 0 == EmployeeVacationQuota.adjust_quota(5, 5)
    end
  end

  describe "week_quota/3" do
    test "returns amount specified by full weeks if it is the same as the max_minutes" do
      insert!(:round)
      insert!(:group)
      emp = insert!(:employee_ranking)

      insert!(:employee_vacation_quota, %{
        weekly_quota: 2,
        maximum_minutes: 4800,
        interval_start_date: ~D[2021-01-01],
        interval_end_date: ~D[2021-12-31]
      })

      assert 2 = EmployeeVacationQuota.week_quota(emp, ~D[2021-01-01], ~D[2021-12-31])
    end

    test "Does not exceed the maximum minutes for FT operator" do
      insert!(:round)
      insert!(:group)
      emp = insert!(:employee_ranking, %{job_class: "000100"})

      insert!(:employee_vacation_quota, %{
        weekly_quota: 4,
        maximum_minutes: 7200,
        interval_start_date: ~D[2021-01-01],
        interval_end_date: ~D[2021-12-31]
      })

      assert 3 = EmployeeVacationQuota.week_quota(emp, ~D[2021-01-01], ~D[2021-03-01])
    end

    test "Does not exceed the maximum minutes for PT operator" do
      insert!(:round)
      insert!(:group)
      emp = insert!(:employee_ranking, %{job_class: "001100"})

      insert!(:employee_vacation_quota, %{
        weekly_quota: 5,
        maximum_minutes: 7200,
        interval_start_date: ~D[2021-01-01],
        interval_end_date: ~D[2021-12-31]
      })

      assert 4 = EmployeeVacationQuota.week_quota(emp, ~D[2021-01-01], ~D[2021-03-01])
    end
  end
end

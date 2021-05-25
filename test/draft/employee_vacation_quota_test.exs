defmodule Draft.EmployeeVacationQuotaTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.EmployeeVacationQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      emp_quota =
        EmployeeVacationQuota.from_parts([
          "00001",
          "01/01/2021",
          "12/31/2021",
          "2",
          "5",
          nil,
          "06/30/2021",
          "1",
          "5",
          "10h30"
        ])

      assert %EmployeeVacationQuota{
               employee_id: "00001",
               quota_interval_start_date: ~D[2021-01-01],
               quota_interval_end_date: ~D[2021-12-31],
               weekly_quota_value: 2,
               dated_quota_value: 5,
               restricted_week_quota_value: nil,
               available_after_date: ~D[2021-06-30],
               available_after_weekly_quota_value: 1,
               available_after_dated_quota_value: 5,
               maximum_minutes: 630
             } = emp_quota
    end
  end
end

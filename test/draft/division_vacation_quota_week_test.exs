defmodule Draft.DivisionVacationQuotaWeekTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.DivisionVacationQuotaWeek

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_week =
        DivisionVacationQuotaWeek.from_parts([
          "125",
          "FTVacQuota",
          "02/11/2021",
          "02/17/2021",
          "5",
          "0"
        ])

      assert %DivisionVacationQuotaWeek{
               division_id: "125",
               employee_selection_set: "FTVacQuota",
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               quota_value: 5,
               is_restricted_week: false
             } = div_quota_week
    end
  end
end

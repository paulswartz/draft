defmodule Draft.DivisionVacationWeekQuotaTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.DivisionVacationWeekQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_week =
        DivisionVacationWeekQuota.from_parts([
          "125",
          "FTVacQuota",
          "1",
          "02/11/2021",
          "02/17/2021",
          "5",
          "0"
        ])

      assert %DivisionVacationWeekQuota{
               division_id: "125",
               employee_selection_set: "FTVacQuota",
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               quota: 5,
               is_restricted_week: false
             } = div_quota_week
    end
  end
end

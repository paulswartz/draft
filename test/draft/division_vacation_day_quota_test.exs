defmodule Draft.DivisionVacationDayQuotaTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.DivisionVacationDayQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_dated =
        DivisionVacationDayQuota.from_parts([
          "125",
          "FTVacQuota",
          "02/11/2021",
          "5"
        ])

      assert %DivisionVacationDayQuota{
               division_id: "125",
               employee_selection_set: "FTVacQuota",
               date: ~D[2021-02-11],
               quota: 5
             } = div_quota_dated
    end
  end
end

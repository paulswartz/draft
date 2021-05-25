defmodule Draft.DivisionVacationQuotaDatedTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.DivisionVacationQuotaDated

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_dated =
        DivisionVacationQuotaDated.from_parts([
          "125",
          "FTVacQuota",
          "02/11/2021",
          "5"
        ])

      assert %DivisionVacationQuotaDated{
               division_id: "125",
               employee_selection_set: "FTVacQuota",
               vacation_date: ~D[2021-02-11],
               quota_value: 5
             } = div_quota_dated
    end
  end
end

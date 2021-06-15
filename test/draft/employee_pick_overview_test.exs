defmodule Draft.EmployeePickOverviewTest do
  use Draft.DataCase
  alias Draft.EmployeePickOverview

  describe "get_latest/1" do
    test "Returns pick overview for present employee" do
      Draft.Factory.insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 2,
        group_size: 10
      })

      assert %EmployeePickOverview{employee_id: "00002", rank: 2} =
               EmployeePickOverview.get_latest("00002")
    end

    test "Returns nil if employee not present" do
      assert nil == EmployeePickOverview.get_latest("00002")
    end
  end
end

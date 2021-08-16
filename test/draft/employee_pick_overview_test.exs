defmodule Draft.EmployeePickOverviewTest do
  use Draft.DataCase
  alias Draft.EmployeePickOverview

  describe "get_latest/1" do
    test "Returns pick overview for present employee" do
      Draft.Factory.insert_round_with_employees(2)

      assert %EmployeePickOverview{
               employee_id: "00002",
               rank: 2,
               job_class: "000100",
               round_id: "Vacation",
               process_id: "BUS22021-122"
             } = EmployeePickOverview.get_latest("00002")
    end

    test "Returns nil if employee not present" do
      assert nil == EmployeePickOverview.get_latest("00002")
    end
  end
end

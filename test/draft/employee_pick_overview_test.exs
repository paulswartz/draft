defmodule Draft.EmployeeVacationPickOverviewTest do
  use Draft.DataCase
  alias Draft.EmployeeVacationPickOverview

  describe "open_round/1" do
    test "Returns pick overview for present employee" do
      Draft.Factory.insert_round_with_employees(
        %{
          round_opening_date: Date.add(Date.utc_today(), -5),
          round_closing_date: Date.add(Date.utc_today(), 5)
        },
        %{group_size: 2, employee_count: 2}
      )

      assert %EmployeeVacationPickOverview{
               employee_id: "00002",
               rank: 2,
               job_class: "000100",
               round_id: "Vacation",
               process_id: "BUS22021-122"
             } = EmployeeVacationPickOverview.open_round("00002")
    end

    test "Returns nil if no currently open round" do
      Draft.Factory.insert_round_with_employees(
        %{
          round_opening_date: Date.add(Date.utc_today(), -5),
          round_closing_date: Date.add(Date.utc_today(), -3)
        },
        %{group_size: 2, employee_count: 2}
      )

      assert nil == EmployeeVacationPickOverview.open_round("00002")
    end

    test "Returns nil if employee not present" do
      assert nil == EmployeeVacationPickOverview.open_round("00002")
    end
  end
end

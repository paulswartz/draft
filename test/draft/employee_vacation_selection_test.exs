defmodule Draft.EmployeeVacationSelectionTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.EmployeeVacationSelection

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      emp_vacation_selections =
        EmployeeVacationSelection.from_parts([
          "00001",
          "Weekly",
          "02/11/2021",
          "02/17/2021",
          "Annual"
        ])

      assert %EmployeeVacationSelection{
               employee_id: "00001",
               vacation_interval_type: "Weekly",
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               pick_period: "Annual"
             } = emp_vacation_selections
    end
  end
end

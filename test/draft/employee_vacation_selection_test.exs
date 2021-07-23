defmodule Draft.EmployeeVacationSelectionTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.EmployeeVacationSelection

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct for assigned week vacation" do
      emp_vacation_selections =
        EmployeeVacationSelection.from_parts([
          "00001",
          "Weekly",
          "02/11/2021",
          "02/17/2021",
          "Effective",
          "Annual",
          "122",
          "000100"
        ])

      assert %EmployeeVacationSelection{
               employee_id: "00001",
               vacation_interval_type: :week,
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               status: :assigned,
               pick_period: "Annual",
               division_id: "122",
               job_class: "000100"
             } = emp_vacation_selections
    end

    test "Successfully map an ordered list of parts into a struct for cancelled day vacation" do
      emp_vacation_selections =
        EmployeeVacationSelection.from_parts([
          "00001",
          "Dated",
          "02/11/2021",
          "02/17/2021",
          "Cancelled",
          "Annual",
          "122",
          "000100"
        ])

      assert %EmployeeVacationSelection{
               employee_id: "00001",
               vacation_interval_type: :day,
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               status: :cancelled,
               pick_period: "Annual",
               division_id: "122",
               job_class: "000100"
             } = emp_vacation_selections
    end
  end
end

defmodule Draft.EmployeeVacationAssignmentTest do
  use ExUnit.Case
  alias Draft.EmployeeVacationAssignment

  describe "to_csv_row/1" do
    test "correct values" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|1|1\n" =
               IO.iodata_to_binary(
                 EmployeeVacationAssignment.to_csv_row(%EmployeeVacationAssignment{
                   employee_id: "0001",
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-08],
                   is_week?: true
                 })
               )
    end

    test "format for unassigned vacation" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|0|1\n" =
               IO.iodata_to_binary(
                 EmployeeVacationAssignment.to_csv_row(%EmployeeVacationAssignment{
                   employee_id: "0001",
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-08],
                   is_week?: true,
                   assigned?: false
                 })
               )
    end
  end
end

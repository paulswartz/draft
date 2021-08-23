defmodule Draft.WorkAssignmentTest do
  use Draft.DataCase
  alias Draft.WorkAssignment

  describe "from_parts/1" do
    test "Successfully parses work assignment" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "11/20/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "12345",
          "1",
          "09/01/2021",
          "12/01/2021",
          "000100",
          "102030",
          "1020304",
          "23456"
        ])

      assert %{
               employee_id: "00001",
               is_dated_exception: false,
               operating_date: ~D[2021-11-20],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 12_345,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "102030",
               duty_internal_id: 1_020_304
             } = work_assignment
    end

    test "Successfully parses work assignment with tripper" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "11/20/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "12345",
          "1",
          "09/01/2021",
          "12/01/2021",
          "000100",
          "102030,102031",
          "1020304,1020305",
          "23456"
        ])

      assert %{
               employee_id: "00001",
               is_dated_exception: false,
               operating_date: ~D[2021-11-20],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 12_345,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "102030",
               duty_internal_id: 1_020_304
             } = work_assignment
    end

    test "Successfully parses work assignment without duty" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "11/20/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "12345",
          "1",
          "09/01/2021",
          "12/01/2021",
          "000100",
          "OFF",
          "",
          ""
        ])

      assert %{
               employee_id: "00001",
               is_dated_exception: false,
               operating_date: ~D[2021-11-20],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 12_345,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "OFF",
               duty_internal_id: nil
             } = work_assignment
    end
  end
end

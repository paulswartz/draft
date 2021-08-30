defmodule Draft.WorkAssignmentTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.WorkAssignment

  @four_three_duty_id 22_222
  @five_two_duty_id 11_111

  setup do
    insert_work_round([
      %{
        session_id: "test_session",
        roster_set_internal_id: 123_456,
        available_rosters: [
          %{
            work_off_ratio: :four_three,
            is_available: true,
            roster_id: "roster01",
            roster_days: [%{day: "08/23/2021", duty_id: @four_three_duty_id}]
          },
          %{
            work_off_ratio: :five_two,
            is_available: true,
            roster_id: "roster02",
            roster_days: [%{day: "08/23/2021", duty_id: @five_two_duty_id}]
          }
        ]
      }
    ])
  end

  describe "from_parts/1" do
    test "Successfully parses work assignment" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "08/23/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "123456",
          "1",
          "09/01/2021",
          "12/01/2021",
          "000100",
          "102030",
          "11111",
          "23456"
        ])

      assert %{
               employee_id: "00001",
               is_dated_exception: false,
               operating_date: ~D[2021-08-23],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 123_456,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "102030",
               duty_internal_id: 11_111,
               hours_worked: 8
             } = work_assignment
    end

    test "Successfully parses work assignment with tripper" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "08/23/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "123456",
          "1",
          "09/01/2021",
          "12/01/2021",
          "000100",
          "102030,102031",
          "11111,1020305",
          "23456"
        ])

      assert %{
               employee_id: "00001",
               is_dated_exception: false,
               operating_date: ~D[2021-08-23],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 123_456,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "102030",
               duty_internal_id: 11_111,
               hours_worked: 8
             } = work_assignment
    end

    test "Successfully parses work assignment without duty" do
      work_assignment =
        WorkAssignment.from_parts([
          "00001",
          "0",
          "08/23/2021",
          "1",
          "0",
          "01/01/1999",
          "122",
          "123456",
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
               operating_date: ~D[2021-08-23],
               is_vr: true,
               division_id: "122",
               roster_set_internal_id: 123_456,
               is_from_primary_pick: true,
               job_class: "000100",
               assignment: "OFF",
               duty_internal_id: nil
             } = work_assignment
    end

    test "hours_worked is nil if VR" do
      assert %{hours_worked: nil} =
               :ft
               |> work_assignment_parts_no_duty("VR")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 8 if 8 hr list & full time" do
      assert %{hours_worked: 8} =
               :ft
               |> work_assignment_parts_no_duty("LR08")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 8 if 8 hr list represented old way ('LR')" do
      assert %{hours_worked: 8} =
               :ft
               |> work_assignment_parts_no_duty("LR")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 10 if 10 hr list & full time" do
      assert %{hours_worked: 10} =
               :ft
               |> work_assignment_parts_no_duty("LR10")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 6 if LRP and part-time" do
      assert %{hours_worked: 6} =
               :pt
               |> work_assignment_parts_no_duty("LRP")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 0 if off" do
      assert %{hours_worked: 0} =
               :ft
               |> work_assignment_parts_no_duty("OFF")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is nil if off list full-time" do
      assert %{hours_worked: nil} =
               :ft
               |> work_assignment_parts_no_duty("OL")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 0 if off list part-time" do
      assert %{hours_worked: 6} =
               :pt
               |> work_assignment_parts_no_duty("OLP")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 6 if VR part time" do
      assert %{hours_worked: 6} =
               :pt
               |> work_assignment_parts_no_duty("VRP")
               |> Draft.WorkAssignment.from_parts()
    end

    test "hours_worked is 8 if full-time operator ahs duty w/ 5/2 roster position" do
      assert %{hours_worked: 8} =
               :ft
               |> work_assignment_parts_with_duty(@five_two_duty_id, "08/23/2021")
               |> Draft.WorkAssignment.from_parts()
    end

    test "10 hours if full-time operator ahs duty w/ 4/3 roster position" do
      assert %{hours_worked: 10} =
               :ft
               |> work_assignment_parts_with_duty(@four_three_duty_id, "08/23/2021")
               |> Draft.WorkAssignment.from_parts()
    end

    test "6 hours if full-time operator has duty w/ 5/2 roster position" do
      assert %{hours_worked: 6} =
               :pt
               |> work_assignment_parts_with_duty(@five_two_duty_id, "08/23/2021")
               |> Draft.WorkAssignment.from_parts()
    end
  end

  @job_class_category_map %{ft: "000100", pt: "001100"}

  defp work_assignment_parts_no_duty(job_class_category, assignment) do
    [
      "00001",
      "0",
      "11/20/2021",
      "1",
      "0",
      "01/01/1999",
      "122",
      "123456",
      "1",
      "09/01/2021",
      "12/01/2021",
      Map.get(@job_class_category_map, job_class_category),
      assignment,
      "",
      ""
    ]
  end

  defp work_assignment_parts_with_duty(job_class_category, duty_id, operating_date) do
    [
      "00001",
      "0",
      operating_date,
      "1",
      "0",
      "01/01/1999",
      "122",
      "123456",
      "1",
      "09/01/2021",
      "12/01/2021",
      Map.get(@job_class_category_map, job_class_category),
      "assignment_id",
      Integer.to_string(duty_id),
      "23456"
    ]
  end
end

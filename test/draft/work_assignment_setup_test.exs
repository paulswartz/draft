defmodule Draft.WorkAssignmentSetupTest do
  use ExUnit.Case
  use Draft.DataCase
  import Draft.Factory

  @pt_job_class "001100"
  describe "setup/1" do
    test "stores work assignment w/ correct hours worked for operator working duty" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :five_two,
              is_available: true,
              roster_id: "roster02",
              roster_days: [
                %{day: "Monday", duty_id: 11_111},
                %{day: "Tuesday", duty_id: 11_111},
                %{day: "Wednesday", duty_id: 11_111},
                %{day: "Thursday", duty_id: 11_111},
                %{day: "Friday", duty_id: 11_111},
                %{day: "Saturday", duty_id: 11_111},
                %{day: "Sunday", duty_id: 11_111}
              ]
            }
          ]
        }
      ])

      Draft.WorkAssignmentSetup.setup("../../test/support/test_data/test_work_assignments.csv")
    end

    test "stores work assignment w/ correct hours worked for operator working list" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :five_two,
              is_available: true,
              roster_id: "roster02",
              roster_days: [
                %{day: "Monday", duty_id: 11_111},
                %{day: "Tuesday", duty_id: 11_111},
                %{day: "Wednesday", duty_id: 11_111},
                %{day: "Thursday", duty_id: 11_111},
                %{day: "Friday", duty_id: 11_111},
                %{day: "Saturday", duty_id: 11_111},
                %{day: "Sunday", duty_id: 11_111}
              ]
            }
          ]
        }
      ])

      Draft.WorkAssignmentSetup.setup("../../test/support/test_data/test_work_assignments.csv")

      assert %{hours_worked: 8} =
               Draft.Repo.get_by!(Draft.WorkAssignment,
                 operating_date: ~D[2021-09-01],
                 employee_id: "00002"
               )
    end

    test "data is updated on expected on re-import" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :five_two,
              is_available: true,
              roster_id: "roster02",
              roster_days: [
                %{day: "Monday", duty_id: 11_111},
                %{day: "Tuesday", duty_id: 11_111},
                %{day: "Wednesday", duty_id: 11_111},
                %{day: "Thursday", duty_id: 11_111},
                %{day: "Friday", duty_id: 11_111},
                %{day: "Saturday", duty_id: 11_111},
                %{day: "Sunday", duty_id: 11_111}
              ]
            }
          ]
        }
      ])

      Draft.WorkAssignmentSetup.setup("../../test/support/test_data/test_work_assignments.csv")

      Draft.WorkAssignmentSetup.setup(
        "../../test/support/test_data/test_work_assignments_updated.csv"
      )

      assert nil ==
               Draft.Repo.get_by(Draft.WorkAssignment,
                 operating_date: ~D[2021-09-01],
                 employee_id: "00002"
               )

      assert %{hours_worked: 8} =
               Draft.Repo.get_by(Draft.WorkAssignment,
                 operating_date: ~D[2021-09-01],
                 employee_id: "00001"
               )
    end
  end

  describe "work_assignment_with_hours/1" do
    test "8 hours if 8 hr list & full time" do
      assert %{hours_worked: 8} =
               :work_assignment
               |> build(assignment: "LR08")
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "8 hours if 8 hr list & part time" do
      assert %{hours_worked: 8} =
               :work_assignment
               |> build(assignment: "LR08", job_class: @pt_job_class)
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "10 hours if 10 hr list & full time" do
      assert %{hours_worked: 10} =
               :work_assignment
               |> build(assignment: "LR10")
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "10 hours if 10 hr list & part time" do
      assert %{hours_worked: 10} =
               :work_assignment
               |> build(assignment: "LR10", job_class: @pt_job_class)
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "0 hours if off" do
      assert %{hours_worked: 0} =
               :work_assignment
               |> build(assignment: "OFF")
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "0 hours if off list" do
      assert %{hours_worked: 0} =
               :work_assignment
               |> build(assignment: "OL")
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "0 hours if off list part-time" do
      assert %{hours_worked: 0} =
               :work_assignment
               |> build(assignment: "OLP")
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "8 hours if full-time operator ahs duty w/ 5/2 roster position" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :five_two,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert %{hours_worked: 8} =
               :work_assignment
               |> build(
                 assignment: "121212",
                 duty_internal_id: 11_111,
                 operating_date: ~D[2021-08-23],
                 roster_set_internal_id: 123_456
               )
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "10 hours if full-time operator ahs duty w/ 4/3 roster position" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :four_three,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert %{hours_worked: 10} =
               :work_assignment
               |> build(
                 assignment: "121212",
                 duty_internal_id: 11_111,
                 operating_date: ~D[2021-08-23],
                 roster_set_internal_id: 123_456
               )
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end

    test "6 hours if full-time operator ahs duty w/ 5/2 roster position" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_ratio: :five_two,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert %{hours_worked: 6} =
               :work_assignment
               |> build(
                 assignment: "121212",
                 duty_internal_id: 11_111,
                 operating_date: ~D[2021-08-23],
                 roster_set_internal_id: 123_456,
                 job_class: @pt_job_class
               )
               |> Draft.WorkAssignmentSetup.work_assignment_with_hours()
    end
  end
end

defmodule Draft.WorkAssignmentSetupTest do
  use ExUnit.Case
  use Draft.DataCase
  import Draft.Factory

  setup do
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
  end

  describe "setup/1" do
    test "stores work assignment w/ correct hours worked for operator working duty" do
      Draft.WorkAssignmentSetup.setup("../../test/support/test_data/test_work_assignments.csv")
    end

    test "stores work assignment w/ correct hours worked for operator working list" do
      Draft.WorkAssignmentSetup.setup("../../test/support/test_data/test_work_assignments.csv")

      assert %{hours_worked: 8} =
               Draft.Repo.get_by!(Draft.WorkAssignment,
                 operating_date: ~D[2021-09-01],
                 employee_id: "00002"
               )
    end

    test "data is updated on expected on re-import" do
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
end

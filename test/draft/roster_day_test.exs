defmodule Draft.RosterDayTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.RosterDay

  describe "from_parts/1" do
    test "Successfully parses roster day for day of week" do
      roster_set =
        RosterDay.from_parts([
          "BUS22021",
          "roster_set_id",
          "1234",
          "1-BB",
          "122155",
          "0",
          "Monday",
          "LR08",
          "",
          "4321"
        ])

      assert %{
               booking_id: "BUS22021",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               roster_id: "1-BB",
               roster_position_id: "122155",
               roster_position_internal_id: 0,
               day: "Monday",
               assignment: "LR08",
               duty_internal_id: nil,
               crew_schedule_internal_id: 4321
             } = roster_set
    end

    test "Successfully parses roster day for dated" do
      roster_set =
        RosterDay.from_parts([
          "BUS22021",
          "roster_set_id",
          "1234",
          "1-BB",
          "122155",
          "0",
          "04/05/2021",
          "1001",
          "2002",
          "4321"
        ])

      assert %{
               booking_id: "BUS22021",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               roster_id: "1-BB",
               roster_position_id: "122155",
               roster_position_internal_id: 0,
               day: "04/05/2021",
               assignment: "1001",
               duty_internal_id: 2002,
               crew_schedule_internal_id: 4321
             } = roster_set
    end
  end

  describe "work_off_ratio_for_duty/3" do
    test "returns expected value when there is a roster day for the given date" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_off_ratio: :five_two,
              is_available: true,
              roster_id: "roster01",
              roster_days: [%{day: "08/23/2021", duty_id: 11_111}]
            },
            %{
              work_off_ratio: :four_three,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert :five_two == Draft.RosterDay.work_off_ratio_for_duty(123_456, 11_111, ~D[2021-08-23])
    end

    test "returns expected value when there is not a roster day for the given date (base schedule)" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_off_ratio: :four_three,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert :four_three ==
               Draft.RosterDay.work_off_ratio_for_duty(123_456, 11_111, ~D[2021-08-23])
    end

    test "returns nil if roster day is VR" do
      insert_work_round([
        %{
          session_id: "test_session",
          roster_set_internal_id: 123_456,
          available_rosters: [
            %{
              work_off_ratio: nil,
              is_available: true,
              roster_id: "roster02",
              roster_days: [%{day: "Monday", duty_id: 11_111}]
            }
          ]
        }
      ])

      assert nil == Draft.RosterDay.work_off_ratio_for_duty(123_456, 11_111, ~D[2021-08-23])
    end
  end
end

defmodule Draft.RosterDayTest do
  use Draft.DataCase
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
end

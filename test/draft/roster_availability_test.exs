defmodule Draft.RosterAvailabilityTest do
  use Draft.DataCase
  alias Draft.RosterAvailability

  describe "from_parts/1" do
    test "Parses roster availability with 5/2 schedule" do
      roster_availability =
        RosterAvailability.from_parts([
          "BUS22021",
          "FT_VAC_WEEKS",
          "roster_set_id",
          "1234",
          "1-BB",
          "5/2",
          "1"
        ])

      assert %{
               booking_id: "BUS22021",
               session_id: "FT_VAC_WEEKS",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               roster_id: "1-BB",
               work_off_ratio: :five_two,
               is_available: true
             } = roster_availability
    end

    test "Parses roster availability with 4/3 schedule" do
      roster_availability =
        RosterAvailability.from_parts([
          "BUS22021",
          "FT_VAC_WEEKS",
          "roster_set_id",
          "1234",
          "1-BB",
          "4/3",
          "1"
        ])

      assert %{
               booking_id: "BUS22021",
               session_id: "FT_VAC_WEEKS",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               roster_id: "1-BB",
               work_off_ratio: :four_three,
               is_available: true
             } = roster_availability
    end

    test "Parses roster availability with unspecified schedule" do
      roster_availability =
        RosterAvailability.from_parts([
          "BUS22021",
          "FT_VAC_WEEKS",
          "roster_set_id",
          "1234",
          "1-BB",
          "",
          "1"
        ])

      assert %{
               booking_id: "BUS22021",
               session_id: "FT_VAC_WEEKS",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               roster_id: "1-BB",
               work_off_ratio: :unspecified,
               is_available: true
             } = roster_availability
    end
  end
end

defmodule Draft.RosterSetTest do
  use Draft.DataCase
  alias Draft.RosterSet

  describe "from_parts/1" do
    test "Successfully parses roster set" do
      roster_set =
        RosterSet.from_parts([
          "BUS22021",
          "FT_VAC_WEEKS",
          "Rsc122",
          "roster_set_id",
          "1234",
          "1",
          "base"
        ])

      assert %{
               booking_id: "BUS22021",
               session_id: "FT_VAC_WEEKS",
               scheduling_unit: "Rsc122",
               roster_set_id: "roster_set_id",
               roster_set_internal_id: 1234,
               scenario: 1,
               service_context: "base"
             } = roster_set
    end
  end
end

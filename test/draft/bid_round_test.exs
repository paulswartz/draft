defmodule Draft.BidRoundTest do
  use ExUnit.Case
  alias Draft.BidRound

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      round_struct =
        BidRound.from_parts([
          "BUS1220_125",
          "Work",
          "02/09/2021",
          "03/03/2021",
          "Work",
          "1",
          nil,
          "122",
          "Arborway",
          "BUS22021",
          "03/14/2021",
          "06/19/2021"
        ])

      assert [
               "BUS1220_125",
               "Work",
               ~D[2021-02-09],
               ~D[2021-03-03],
               "Work",
               1,
               nil,
               "122",
               "Arborway",
               "BUS22021",
               ~D[2021-03-14],
               ~D[2021-06-19]
             ] == [
               round_struct.process_id,
               round_struct.round_id,
               round_struct.round_opening_date,
               round_struct.round_closing_date,
               round_struct.bid_type,
               round_struct.rank,
               round_struct.service_context,
               round_struct.division_id,
               round_struct.division_description,
               round_struct.booking_id,
               round_struct.rating_period_start_date,
               round_struct.rating_period_end_date
             ]
    end
  end
end

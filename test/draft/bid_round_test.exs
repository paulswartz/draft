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

      assert %{
               process_id: "BUS1220_125",
               round_id: "Work",
               round_opening_date: ~D[2021-02-09],
               round_closing_date: ~D[2021-03-03],
               bid_type: :work,
               rank: 1,
               service_context: nil,
               division_id: "122",
               division_description: "Arborway",
               booking_id: "BUS22021",
               rating_period_start_date: ~D[2021-03-14],
               rating_period_end_date: ~D[2021-06-19]
             } = round_struct
    end
  end
end

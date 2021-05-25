defmodule Draft.BidGroupTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.BidGroup

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      group_struct =
        BidGroup.from_parts([
          "BUS1220_125",
          "Work",
          "1",
          "02/11/2021",
          "500p"
        ])

      assert %{
               process_id: "BUS1220_125",
               round_id: "Work",
               group_number: 1,
               cutoff_datetime: ~U[2021-02-11 22:00:00Z]
             } = group_struct
    end
  end
end

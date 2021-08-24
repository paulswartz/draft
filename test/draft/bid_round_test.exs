defmodule Draft.BidRoundTest do
  use Draft.DataCase
  import Draft.Factory
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

  describe "calculate_point_of_equivalence/1" do
    test "All operators need to be forced" do
      round =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 1, "00002" => 1},
          %{}
        )
        |> to_round()

      %{has_poe_been_reached: true, employees_to_force: [{"00001", 1}, {"00002", 1}]} =
        Draft.BidRound.calculate_point_of_equivalence(round)
    end

    test "Only the lowest ranking operator would need to be forced" do
      round =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 1, "00002" => 2},
          %{}
        )
        |> to_round()

      %{amount_to_force: 2, has_poe_been_reached: false, employees_to_force: [{"00002", 2}]} =
        Draft.BidRound.calculate_point_of_equivalence(round)
    end

    test "An operator would be forced only as much of their balance as is necessary" do
      round =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 5},
          %{}
        )
        |> to_round()

      %{amount_to_force: 2, has_poe_been_reached: true, employees_to_force: [{"00001", 2}]} =
        Draft.BidRound.calculate_point_of_equivalence(round)
    end
  end

  defp to_round(round_spec) do
    Repo.one!(
      from r in Draft.BidRound,
        where: r.round_id == ^round_spec.round_id and r.process_id == ^round_spec.process_id
    )
  end
end

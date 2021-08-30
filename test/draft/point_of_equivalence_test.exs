defmodule Draft.PointOfEquivalenceTest do
  use Draft.DataCase
  import Draft.Factory

  describe "calculate/1" do
    test "All operators need to be forced" do
      session =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 1, "00002" => 1},
          %{}
        )
        |> Draft.BidSession.single_session_for_round()

      %{has_poe_been_reached: true, employees_to_force: [{"00001", 1}, {"00002", 1}]} =
        Draft.PointOfEquivalence.calculate(session)
    end

    test "Only the lowest ranking operator would need to be forced" do
      session =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 1, "00002" => 2},
          %{}
        )
        |> Draft.BidSession.single_session_for_round()

      %{amount_to_force: 2, has_poe_been_reached: false, employees_to_force: [{"00002", 2}]} =
        Draft.PointOfEquivalence.calculate(session)
    end

    test "An operator would be forced only as much of their balance as is necessary" do
      session =
        :week
        |> insert_round_with_employees_and_vacation(
          %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
          %{"00001" => 5},
          %{}
        )
        |> Draft.BidSession.single_session_for_round()

      %{amount_to_force: 2, has_poe_been_reached: true, employees_to_force: [{"00001", 2}]} =
        Draft.PointOfEquivalence.calculate(session)
    end
  end
end

defmodule Draft.BidSessionTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.BidSession

  setup do
    insert!(:round, %{round_id: "round_1", process_id: "process_1"})
    :ok
  end

  describe "from_parts/1" do
    test "Successfully weekly vacation session" do
      session =
        BidSession.from_parts([
          "BUS22021-122",
          "Vacation",
          "Vac_FT",
          "Vacation",
          "Only weekly",
          nil,
          nil,
          "122",
          "booking_id",
          "08/29/2021",
          "12/31/2021"
        ])

      assert %{
               process_id: "BUS22021-122",
               round_id: "Vacation",
               session_id: "Vac_FT",
               booking_id: "booking_id",
               type: :vacation,
               type_allowed: :week,
               service_context: nil,
               scheduling_unit: nil,
               division_id: "122",
               rating_period_start_date: ~D[2021-08-29],
               rating_period_end_date: ~D[2021-12-31]
             } = session
    end

    test "Successfully map dated vacation session" do
      session =
        BidSession.from_parts([
          "BUS22021-122",
          "Vacation",
          "Vac_FT",
          "Vacation",
          "Only dated",
          nil,
          nil,
          "122",
          "booking_id",
          "08/29/2021",
          "12/31/2021"
        ])

      assert %{
               process_id: "BUS22021-122",
               round_id: "Vacation",
               session_id: "Vac_FT",
               booking_id: "booking_id",
               type: :vacation,
               type_allowed: :day,
               service_context: nil,
               scheduling_unit: nil,
               division_id: "122",
               rating_period_start_date: ~D[2021-08-29],
               rating_period_end_date: ~D[2021-12-31]
             } = session
    end

    test "Successfully map work session" do
      session =
        BidSession.from_parts([
          "BUS22021-122",
          "work_round",
          "Work_FT",
          "Work",
          nil,
          nil,
          nil,
          "122",
          "booking_id",
          "08/29/2021",
          "12/31/2021"
        ])

      assert %{
               process_id: "BUS22021-122",
               round_id: "work_round",
               session_id: "Work_FT",
               booking_id: "booking_id",
               type: :work,
               type_allowed: nil,
               service_context: nil,
               scheduling_unit: nil,
               division_id: "122",
               rating_period_start_date: ~D[2021-08-29],
               rating_period_end_date: ~D[2021-12-31]
             } = session
    end
  end

  describe "vacation_interval/1" do
    test "Returns day for vacation day session" do
      insert!(:session, %{
        round_id: "round_1",
        process_id: "process_1",
        type: :vacation,
        type_allowed: :day
      })

      assert :day =
               Draft.BidSession.vacation_interval(%{
                 round_id: "round_1",
                 process_id: "process_1"
               })
    end

    test "Returns week for vacation week session" do
      insert!(:session, %{
        round_id: "round_1",
        process_id: "process_1",
        type: :vacation,
        type_allowed: :week
      })

      assert :week =
               Draft.BidSession.vacation_interval(%{
                 round_id: "round_1",
                 process_id: "process_1"
               })
    end

    test "Returns nil if passed work session" do
      insert!(:session, %{
        round_id: "round_1",
        process_id: "process_1",
        type: :work,
        type_allowed: nil
      })

      assert nil ==
               Draft.BidSession.vacation_interval(%{
                 round_id: "round_1",
                 process_id: "process_1"
               })
    end
  end

  describe "calculate_point_of_equivalence/1" do
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
        Draft.BidSession.calculate_point_of_equivalence(session)
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
        Draft.BidSession.calculate_point_of_equivalence(session)
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
        Draft.BidSession.calculate_point_of_equivalence(session)
    end
  end
end

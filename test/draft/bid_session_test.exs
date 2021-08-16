defmodule Draft.BidSessionTest do
  use ExUnit.Case
  alias Draft.BidSession

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
end

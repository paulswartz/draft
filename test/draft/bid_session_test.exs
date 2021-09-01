defmodule Draft.BidSessionTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.BidSession

  setup do
    insert!(:round, %{round_id: "round_1", process_id: "process_1"})
    insert!(:group, %{round_id: "round_1", process_id: "process_1"})
    insert!(:employee_ranking, %{round_id: "round_1", process_id: "process_1"})
    :ok
  end

  describe "from_parts/1" do
    test "Successfully weekly vacation session" do
      session =
        BidSession.from_parts([
          "process_1",
          "round_1",
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
               process_id: "process_1",
               round_id: "round_1",
               session_id: "Vac_FT",
               booking_id: "booking_id",
               job_class_category: :ft,
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
          "process_1",
          "round_1",
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
               process_id: "process_1",
               round_id: "round_1",
               session_id: "Vac_FT",
               booking_id: "booking_id",
               job_class_category: :ft,
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
          "process_1",
          "round_1",
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
               process_id: "process_1",
               round_id: "round_1",
               session_id: "Work_FT",
               booking_id: "booking_id",
               job_class_category: :ft,
               type: :work,
               type_allowed: nil,
               service_context: nil,
               scheduling_unit: nil,
               division_id: "122",
               rating_period_start_date: ~D[2021-08-29],
               rating_period_end_date: ~D[2021-12-31]
             } = session
    end

    test "Job class category is PT if first employee in round is PT" do
      insert!(:round, %{round_id: "round_2", process_id: "process_2"})
      insert!(:group, %{round_id: "round_2", process_id: "process_2"})

      insert!(:employee_ranking, %{
        round_id: "round_2",
        process_id: "process_2",
        job_class: "001100"
      })

      session =
        BidSession.from_parts([
          "process_2",
          "round_2",
          "Work_PT",
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
               process_id: "process_2",
               round_id: "round_2",
               session_id: "Work_PT",
               booking_id: "booking_id",
               job_class_category: :pt,
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

  describe "vacation_session/1" do
    test "Returns vacation day session" do
      insert!(:session, %{
        round_id: "round_1",
        process_id: "process_1",
        type: :vacation,
        type_allowed: :day
      })

      assert %Draft.BidSession{
               round_id: "round_1",
               process_id: "process_1",
               type: :vacation,
               type_allowed: :day
             } =
               Draft.BidSession.vacation_session(%{
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

      assert %Draft.BidSession{
               round_id: "round_1",
               process_id: "process_1",
               type: :vacation,
               type_allowed: :week
             } =
               Draft.BidSession.vacation_session(%{
                 round_id: "round_1",
                 process_id: "process_1"
               })
    end

    test "Raises error if passed work session" do
      insert!(:session, %{
        round_id: "round_1",
        process_id: "process_1",
        type: :work,
        type_allowed: nil
      })

      assert_raise Ecto.NoResultsError, fn ->
        Draft.BidSession.vacation_session(%{
          round_id: "round_1",
          process_id: "process_1"
        })
      end
    end
  end
end

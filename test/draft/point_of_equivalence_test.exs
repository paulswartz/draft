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

      %{reached?: true, employees_to_force: [{"00001", 1}, {"00002", 1}]} =
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

      %{amount_to_force: 2, reached?: false, employees_to_force: [{"00002", 2}]} =
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

      %{amount_to_force: 2, reached?: true, employees_to_force: [{"00001", 2}]} =
        Draft.PointOfEquivalence.calculate(session)
    end
  end

  describe "calculate/2" do
    test "No employees to force when quota to force is 0" do
      assert %Draft.PointOfEquivalence{
               reached?: false,
               employees_to_force: [],
               amount_to_force: 0
             } =
               Draft.PointOfEquivalence.calculate(
                 [
                   %{
                     employee_id: "00001",
                     job_class: "000100",
                     total_available_minutes: 2400,
                     anniversary_date: nil,
                     minutes_only_available_as_of_anniversary: 0
                   }
                 ],
                 0
               )
    end

    test "Only least senior operator is forced" do
      assert %Draft.PointOfEquivalence{
               reached?: false,
               employees_to_force: [{"00002", 1}],
               amount_to_force: 1
             } =
               Draft.PointOfEquivalence.calculate(
                 [
                   %{
                     employee_id: "00001",
                     job_class: "000100",
                     total_available_minutes: 2400,
                     anniversary_date: nil,
                     minutes_only_available_as_of_anniversary: 0,
                     rank: 1,
                     group_number: 1
                   },
                   %{
                     employee_id: "00002",
                     job_class: "000100",
                     total_available_minutes: 2400,
                     anniversary_date: nil,
                     minutes_only_available_as_of_anniversary: 0,
                     rank: 2,
                     group_number: 1
                   }
                 ],
                 1
               )
    end

    test "Operator can be forced part of their balance" do
      assert %Draft.PointOfEquivalence{
               reached?: true,
               employees_to_force: [{"00001", 1}, {"00002", 1}],
               amount_to_force: 2
             } =
               Draft.PointOfEquivalence.calculate(
                 [
                   %{
                     employee_id: "00001",
                     job_class: "000100",
                     total_available_minutes: 4800,
                     anniversary_date: nil,
                     minutes_only_available_as_of_anniversary: 0,
                     rank: 1,
                     group_number: 1
                   },
                   %{
                     employee_id: "00002",
                     job_class: "000100",
                     total_available_minutes: 2400,
                     anniversary_date: nil,
                     minutes_only_available_as_of_anniversary: 0,
                     rank: 2,
                     group_number: 1
                   }
                 ],
                 2
               )
    end
  end
end

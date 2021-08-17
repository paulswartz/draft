defmodule Draft.DivisionQuotaRankedTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory

  describe "available_to_employee/2" do
    test "Returns weeks in descending order when no preferences" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :week,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :week)
    end

    test "Returns weeks with preference present before weeks w/out preference" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :week,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{},
          %{"00001" => [~D[2021-08-01]]}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :week)
    end

    test "Week Preferences are returned sorted in ascending order" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :week,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{},
          %{"00001" => [~D[2021-08-01], ~D[2021-08-15]]}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: 2,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :week)
    end

    test "Returns days in descending order when no preferences" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :day,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-15],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-08],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-01],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :day)
    end

    test "Returns day with preference present before day w/out preference" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :day,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{},
          %{"00001" => [~D[2021-08-01]]}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-01],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-15],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-08],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :day)
    end

    test "Day preferences are returned sorted in ascending order" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          :day,
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{},
          %{"00001" => [~D[2021-08-01], ~D[2021-08-15]]}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-01],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-15],
                 preference_rank: 2,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-08],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionQuotaRanked.available_to_employee(round, emp, :day)
    end
  end
end

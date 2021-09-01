defmodule Draft.DivisionQuotaTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory

  describe "available_with_employee_rank/2" do
    test "Returns weeks in descending order when no preferences" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end

    test "Returns weeks with preference present before weeks w/out preference" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end

    test "Week Preferences are returned sorted in ascending order" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end

    test "Returns days in descending order when no preferences" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end

    test "Returns day with preference present before day w/out preference" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end

    test "Day preferences are returned sorted in ascending order" do
      round =
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

      session = Draft.BidSession.single_session_for_round(round)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round.round_id,
          process_id: round.process_id,
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
             ] = Draft.DivisionQuota.available_with_employee_rank(session, emp)
    end
  end
end

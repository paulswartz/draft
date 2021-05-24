defmodule Draft.PickDataSetup.BidRoundSetupTest do
  use ExUnit.Case
  use Draft.DataCase
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.PickDataSetup.BidRoundSetup

  setup do
    BidRoundSetup.update_bid_round_data("../../../test/support/testData/test_rounds.csv")
  end

  describe "update_bid_round_data/1" do
    test "Correct number of rounds / groups / employee rankings present" do
      all_rounds = Repo.all(BidRound)
      assert length(all_rounds) == 1
      all_groups = Repo.all(BidGroup)
      assert length(all_groups) == 2
      all_employee_rankings = Repo.all(EmployeeRanking)
      assert length(all_employee_rankings) == 6
    end

    test "Round has expected data changed after importing updated file" do
      initial_round = Repo.get_by!(BidRound, process_id: "BUS22021-122", round_id: "Work")

      assert [~D[2021-03-14], ~D[2021-06-19]] == [
               initial_round.rating_period_start_date,
               initial_round.rating_period_end_date
             ]

      BidRoundSetup.update_bid_round_data(
        "../../../test/support/testData/test_rounds_updated_data.csv"
      )

      updated_round = Repo.get_by!(BidRound, process_id: "BUS22021-122", round_id: "Work")

      assert [~D[2021-03-15], ~D[2021-06-20]] == [
               updated_round.rating_period_start_date,
               updated_round.rating_period_end_date
             ]
    end

    test "Group has expected data changed after importing updated file" do
      initial_group =
        Repo.get_by!(BidGroup, process_id: "BUS22021-122", round_id: "Work", group_number: 1)

      assert ~U[2021-02-11 22:00:00Z] == initial_group.cutoff_datetime

      BidRoundSetup.update_bid_round_data(
        "../../../test/support/testData/test_rounds_updated_data.csv"
      )

      updated_group =
        Repo.get_by!(BidGroup, process_id: "BUS22021-122", round_id: "Work", group_number: 1)

      assert ~U[2021-02-12 23:00:00Z] == updated_group.cutoff_datetime
    end

    test "Employee Ranking has expected data changed after importing updated file" do
      initial_employee_ranking =
        Repo.get_by!(EmployeeRanking,
          process_id: "BUS22021-122",
          round_id: "Work",
          employee_id: "00001"
        )

      assert 1 == initial_employee_ranking.rank

      BidRoundSetup.update_bid_round_data(
        "../../../test/support/testData/test_rounds_updated_data.csv"
      )

      updated_employee_ranking =
        Repo.get_by!(EmployeeRanking,
          process_id: "BUS22021-122",
          round_id: "Work",
          employee_id: "00001"
        )

      assert 3 == updated_employee_ranking.rank
    end
  end
end

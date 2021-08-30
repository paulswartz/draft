defmodule Draft.VacationDistributionRunTest do
  use ExUnit.Case
  use Draft.DataCase
  import Draft.Factory
  alias Draft.VacationDistributionRun

  describe "insert/1" do
    test "Inserts expected run record" do
      run_id =
        VacationDistributionRun.insert(%Draft.BidGroup{
          process_id: "process_1",
          round_id: "vacation_1",
          group_number: 1
        })

      [
        %VacationDistributionRun{
          id: ^run_id,
          process_id: "process_1",
          round_id: "vacation_1",
          group_number: 1
        }
      ] = Draft.Repo.all(VacationDistributionRun)
    end
  end

  describe "mark_as_complete/1" do
    test "Marks only the specified run as complete" do
      run_id_1 =
        VacationDistributionRun.insert(%Draft.BidGroup{
          process_id: "process_1",
          round_id: "vacation_1",
          group_number: 1
        })

      assert original_run_1 = Draft.Repo.one!(VacationDistributionRun)

      run_id_2 =
        VacationDistributionRun.insert(%Draft.BidGroup{
          process_id: "process_1",
          round_id: "vacation_1",
          group_number: 1
        })

      assert is_nil(original_run_1.end_time)
      {:ok, updated_run_1} = VacationDistributionRun.mark_complete(run_id_1)
      assert !is_nil(updated_run_1.end_time)

      assert is_nil(
               Draft.Repo.one!(from r in VacationDistributionRun, where: r.id == ^run_id_2).end_time
             )
    end
  end

  describe "last_distributed_group/1" do
    test "Returns nil when no distributions yet" do
      round = insert!(:round, %{process_id: "process_id", round_id: "round_id"})

      assert nil ==
               VacationDistributionRun.last_distributed_group(round.round_id, round.process_id)
    end

    test "Returns latest group when multiple" do
      round = insert!(:round, %{process_id: "process_id", round_id: "round_id"})
      group1 = insert!(:group, %{process_id: "process_id", round_id: "round_id", group_number: 1})
      group2 = insert!(:group, %{process_id: "process_id", round_id: "round_id", group_number: 2})

      run_1 = VacationDistributionRun.insert(group1)
      VacationDistributionRun.mark_complete(run_1)
      run_2 = VacationDistributionRun.insert(group2)
      VacationDistributionRun.mark_complete(run_2)
      assert 2 = VacationDistributionRun.last_distributed_group(round.round_id, round.process_id)
    end

    test "Does not return group where distribution run hasn't completed" do
      round = insert!(:round, %{process_id: "process_id", round_id: "round_id"})
      group1 = insert!(:group, %{process_id: "process_id", round_id: "round_id", group_number: 1})
      group2 = insert!(:group, %{process_id: "process_id", round_id: "round_id", group_number: 2})

      run_1 = VacationDistributionRun.insert(group1)
      VacationDistributionRun.mark_complete(run_1)
      VacationDistributionRun.insert(group2)
      assert 1 = VacationDistributionRun.last_distributed_group(round.round_id, round.process_id)
    end
  end
end

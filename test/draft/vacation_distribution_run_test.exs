defmodule Draft.VacationDistributionRunTest do
  use ExUnit.Case
  use Draft.DataCase
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
end

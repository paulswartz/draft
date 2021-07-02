defmodule Draft.VacationDistributionRunTest do
  use ExUnit.Case
  use Draft.DataCase
  alias Draft.VacationDistributionRun

  describe "insert/2" do
    test "Inserts expected run record" do
      run_id = VacationDistributionRun.insert("process_1", "vacation_1")

      [%VacationDistributionRun{id: ^run_id, process_id: "process_1", round_id: "vacation_1"}] =
        Draft.Repo.all(VacationDistributionRun)
    end
  end

  describe "mark_as_complete/1" do
    test "Successfully marks as complete existing " do
      run_id = VacationDistributionRun.insert("process_1", "vacation_1")
      {:ok, updated_run} = VacationDistributionRun.mark_complete(run_id)

      assert updated_run.id == run_id
    end
  end
end

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
      assert original_run = Draft.Repo.one!(VacationDistributionRun)
      assert is_nil(original_run.end_time)
      {:ok, updated_run} = VacationDistributionRun.mark_complete(run_id)
      assert !is_nil(updated_run.end_time)
    end
  end
end

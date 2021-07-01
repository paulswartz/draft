defmodule Draft.JobClassHelpersTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.JobClassHelpers

  describe "num_hours_per_day/1" do
    test "8 for full time position" do
      8 = JobClassHelpers.num_hours_per_day("000100")
    end

    test "6 for part time position" do
      6 = JobClassHelpers.num_hours_per_day("001100")
    end
  end

  describe "get_selection_set/1" do
    test "Correct selection set returned" do
      ft = "FTVacQuota"
      pt = "PTVacQuota"
      assert ft == JobClassHelpers.get_selection_set("000100")
      assert ft == JobClassHelpers.get_selection_set("000300")
      assert ft == JobClassHelpers.get_selection_set("000800")
      assert pt == JobClassHelpers.get_selection_set("001100")
      assert pt == JobClassHelpers.get_selection_set("000200")
      assert pt == JobClassHelpers.get_selection_set("000900")
    end
  end
end

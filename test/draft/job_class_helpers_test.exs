defmodule Draft.JobClassHelpersTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.JobClassHelpers
  doctest JobClassHelpers

  describe "num_hours_per_day/2" do
    test "8 for full time position w/ 5/2" do
      8 = JobClassHelpers.num_hours_per_day("000100", :five_two)
    end

    test "10 for full time position w/ 4/3" do
      10 = JobClassHelpers.num_hours_per_day("000100", :four_three)
    end

    test "6 for part time position w/ 5/2" do
      6 = JobClassHelpers.num_hours_per_day("001100", :five_two)
    end
  end

  describe "job_category_for_class/1" do
    test "Correct selection set returned" do
      assert :ft == JobClassHelpers.job_category_for_class("000100")
      assert :ft == JobClassHelpers.job_category_for_class("000300")
      assert :ft == JobClassHelpers.job_category_for_class("000800")
      assert :pt == JobClassHelpers.job_category_for_class("001100")
      assert :pt == JobClassHelpers.job_category_for_class("000200")
      assert :pt == JobClassHelpers.job_category_for_class("000900")
    end
  end

  describe "job_classes_in_category/1" do
    test "correct job_classes_returned for full time" do
      assert Enum.sort(JobClassHelpers.job_classes_in_category(:ft)) == [
               "000100",
               "000300",
               "000800"
             ]

      assert Enum.sort(JobClassHelpers.job_classes_in_category(:pt)) == [
               "000200",
               "000900",
               "001100"
             ]
    end
  end
end

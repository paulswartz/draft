defmodule Draft.EmployeeRankingTest do
  use ExUnit.Case
  alias Draft.EmployeeRanking

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      employee_ranking_struct =
        EmployeeRanking.from_parts([
          "BUS22021-122",
          "Work",
          "1",
          "1",
          "01166",
          "test_name",
          "000100"
        ])

      assert ["BUS22021-122", "Work", 1, 1, "01166", "test_name", "000100"] == [
               employee_ranking_struct.process_id,
               employee_ranking_struct.round_id,
               employee_ranking_struct.group_number,
               employee_ranking_struct.rank,
               employee_ranking_struct.employee_id,
               employee_ranking_struct.name,
               employee_ranking_struct.job_class
             ]
    end
  end
end

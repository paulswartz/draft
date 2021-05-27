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

      assert %{
               process_id: "BUS22021-122",
               round_id: "Work",
               group_number: 1,
               rank: 1,
               employee_id: "01166",
               name: "test_name",
               job_class: "000100"
             } = employee_ranking_struct
    end
  end
end

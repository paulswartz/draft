defmodule Draft.EmployeeRankingTest do
  use Draft.DataCase
  import Draft.Factory
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

  describe "all_remaining_employees/2" do
    test "returns all employees descending when no distributions yet" do
      round =
        insert_round_with_employees(
          %{
            round_id: "round_id",
            process_id: "process_id"
          },
          %{
            :employee_count => 3,
            :group_size => 1
          }
        )

      assert [%{employee_id: "00003"}, %{employee_id: "00002"}, %{employee_id: "00001"}] =
               EmployeeRanking.all_remaining_employees(round, :desc)
    end

    test "returns all employees ascending when no distributions yet" do
      round =
        insert_round_with_employees(
          %{
            round_id: "round_id",
            process_id: "process_id"
          },
          %{
            :employee_count => 3,
            :group_size => 1
          }
        )

      assert [%{employee_id: "00001"}, %{employee_id: "00002"}, %{employee_id: "00003"}] =
               EmployeeRanking.all_remaining_employees(round, :asc)
    end

    test "returns only employees after previously distributed group" do
      round =
        insert_round_with_employees(
          %{
            round_id: "round_id",
            process_id: "process_id"
          },
          %{
            :employee_count => 3,
            :group_size => 1
          }
        )

      Draft.BasicVacationDistributionRunner.distribute_vacation_to_group(
        %{round_id: "round_id", process_id: "process_id", group_number: 1},
        :week
      )

      assert [%{employee_id: "00002"}, %{employee_id: "00003"}] =
               EmployeeRanking.all_remaining_employees(round, :asc)
    end
  end
end

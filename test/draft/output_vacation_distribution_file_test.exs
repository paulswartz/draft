defmodule Draft.OutputVacationDistributionTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.EmployeeVacationAssignment
  alias Draft.OutputVacationDistribution

  describe "output_vacation_distribution_file/1" do
    test "contains assignments in expected format" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|1|1\nvacation|0001|0|01/09/2021|01/09/2021|1|1\n" =
               IO.iodata_to_binary(
                 OutputVacationDistribution.output_vacation_distribution_file(
                   [
                     %EmployeeVacationAssignment{
                       employee_id: "0001",
                       start_date: ~D[2021-01-01],
                       end_date: ~D[2021-01-08],
                       is_week?: true
                     },
                     %EmployeeVacationAssignment{
                       employee_id: "0001",
                       start_date: ~D[2021-01-09],
                       end_date: ~D[2021-01-09],
                       is_week?: false
                     }
                   ],
                   "test/support/test_data/test_vacation_assignment_output.csv"
                 )
               )
    end
  end
end

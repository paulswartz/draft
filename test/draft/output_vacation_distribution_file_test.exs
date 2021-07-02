defmodule Draft.OutputVacationDistributionTest do
  @moduledoc false
  use ExUnit.Case
  alias Draft.OutputVacationDistribution
  alias Draft.VacationDistribution

  describe "output_vacation_distribution_file/1" do
    test "contains assignments in expected format" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|1|1\nvacation|0001|0|01/09/2021|01/09/2021|1|1\n" =
               IO.iodata_to_binary(
                 OutputVacationDistribution.output_vacation_distribution_file(
                   [
                     %VacationDistribution{
                       employee_id: "0001",
                       start_date: ~D[2021-01-01],
                       end_date: ~D[2021-01-08],
                       interval_type: :week
                     },
                     %VacationDistribution{
                       employee_id: "0001",
                       start_date: ~D[2021-01-09],
                       end_date: ~D[2021-01-09],
                       interval_type: :day
                     }
                   ],
                   "test/support/test_data/test_vacation_assignment_output.csv"
                 )
               )
    end
  end
end

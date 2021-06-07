defmodule Draft.OutputVacationDistribution do
  @moduledoc """
  Create a csv file containing the given employee vacation assignments in the hastus-required format.
  """
  alias Draft.EmployeeVacationAssignment

  @spec output_vacation_distribution_file([Draft.EmployeeVacationAssignment.t()], String.t()) ::
          :ok
  def output_vacation_distribution_file(vacation_assignments, output_file_path) do
    {:ok, output_file} = File.open(output_file_path, [:write])

    :ok =
      File.write(
        output_file_path,
        Enum.map(vacation_assignments, &EmployeeVacationAssignment.to_csv_row(&1))
      )

    :ok = File.close(output_file)
  end
end

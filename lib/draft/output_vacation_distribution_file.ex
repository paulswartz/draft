defmodule Draft.OutputVacationDistribution do
  @moduledoc """
  Create a csv file containing the given employee vacation assignments in the hastus-required format.
  """
  alias Draft.VacationDistribution

  @spec output_vacation_distribution_file([Draft.VacationDistribution.t()], String.t()) ::
          [String.t()]
  def output_vacation_distribution_file(vacation_assignments, output_file_path) do
    formatted_data = Enum.map(vacation_assignments, &VacationDistribution.to_csv_row(&1))

    :ok =
      File.write(
        output_file_path,
        formatted_data
      )

    formatted_data
  end
end

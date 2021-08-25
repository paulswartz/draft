defmodule Draft.WorkAssignmentSetup do
  @moduledoc """
  Import the given file specifying the work that each operator is performing on every day of a rating period, with the hours each operator is expected to work each day calculated based on their job class & assignment.
  """
  require Logger

  @spec setup(Draft.ParsingHelpers.filename()) ::
          {:ok, Draft.WorkAssignment.t()}
          | {:error, any()}
  @doc """
  Store the work assignments from the given file in the database with the calculated # of hours to be worked each day.
  """
  def setup(work_file_path \\ "../../data/latest/work_20210811_0128.txt") do
    work_assignments =
      work_file_path
      |> Draft.ParsingHelpers.parse_pipe_separated_file()
      |> Enum.map(&Draft.Parsable.from_parts(Draft.WorkAssignment, &1))

    Draft.Repo.transaction(fn ->
      _deleted_records =
        work_assignments
        |> Enum.map(& &1.division_id)
        |> Enum.uniq()
        |> Draft.WorkAssignment.delete_all_records_for_divisions()

      Enum.each(work_assignments, &Draft.Repo.insert(&1))
    end)
  end
end

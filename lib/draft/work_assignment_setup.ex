defmodule Draft.WorkAssignmentSetup do
  @moduledoc """
  Import the given file specifying the work that each operator is performing on every day of a rating period. Calculate the hours each operator is expected to work each day based on their given job class, assignment, duty id from the file and roster day data already present in the database.
  """
  require Logger

  @spec setup(String.t()) ::
          {:ok, Draft.WorkAssignment.t()}
          | {:error, any()}
  @doc """
  Store the work assignments from the given file in the database with the calculated # of hours
  to be worked each day.
  """
  def setup(work_file_path \\ "../../data/latest/work_20210811_0128.txt") do
    work_assignments =
      work_file_path
      |> Draft.ParsingHelpers.parse_pipe_separated_file()
      |> Enum.map(&Draft.Parsable.from_parts(Draft.WorkAssignment, &1))
      # Filtering out VR for now -- should get this file AFTER VR pick has been completed
      |> Enum.filter(&(&1.assignment != "VR"))
      |> Enum.map(&work_assignment_with_hours(&1))

    # This should probably be an insert_all -- one per operator per day
    Draft.Repo.transaction(fn ->
      # Delete all existing work assignments within the given divisions?
      Enum.each(work_assignments, &Draft.Repo.insert(&1))
    end)
  end

  @spec work_assignment_with_hours(Draft.WorkAssignment.t()) :: Draft.WorkAssignment.t()
  @doc """
  Return a work assignment with the `hours_worked` field populated
  based on the job class, assignment, and duty.
  """
  def work_assignment_with_hours(%Draft.WorkAssignment{assignment: "LR08"} = work_assignment) do
    %{work_assignment | hours_worked: 8}
  end

  def work_assignment_with_hours(%Draft.WorkAssignment{assignment: "LR10"} = work_assignment) do
    %{work_assignment | hours_worked: 10}
  end

  def work_assignment_with_hours(%Draft.WorkAssignment{assignment: "OL"} = work_assignment) do
    # Assumption for now -- 0 hours for OL day
    %{work_assignment | hours_worked: 0}
  end

  def work_assignment_with_hours(%Draft.WorkAssignment{assignment: "OLP"} = work_assignment) do
    # Assumption for now -- 0 hours for OLPT day
    %{work_assignment | hours_worked: 0}
  end

  def work_assignment_with_hours(%Draft.WorkAssignment{assignment: "OFF"} = work_assignment) do
    %{work_assignment | hours_worked: 0}
  end

  def work_assignment_with_hours(
        %Draft.WorkAssignment{
          duty_internal_id: duty_internal_id,
          roster_set_internal_id: roster_set_internal_id,
          job_class: job_class,
          operating_date: date
        } = work_assignment
      ) do
    work_ratio =
      Draft.RosterDay.work_ratio_for_duty(roster_set_internal_id, duty_internal_id, date)

    %{
      work_assignment
      | hours_worked: Draft.JobClassHelpers.num_hours_per_day(job_class, work_ratio)
    }
  end
end

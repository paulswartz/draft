defmodule Draft.EmployeeVacationAssignment do
  @moduledoc """
    Represents vacation time an employee has been assigned.
  """
  alias Draft.FormattingHelpers

  defstruct [
    :employee_id,
    :vacation_interval_type,
    :start_date,
    :end_date,
    :pick_period,
    :forced?,
    assigned?: true,
    quarterly_pick?: true
  ]

  @type t :: %__MODULE__{
          employee_id: String.t(),
          vacation_interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t()
        }
  @spec to_csv_row(Draft.EmployeeVacationAssignment.t()) :: iodata()
  def to_csv_row(assignment) do
    status = if assignment.quarterly_pick?, do: 1, else: 0
    pick_period = if assignment.quarterly_pick?, do: 1, else: 0

    PipeSeparatedParser.dump_to_iodata([
      [
        "vacation",
        assignment.employee_id,
        assignment.vacation_interval_type,
        FormattingHelpers.to_date_string(assignment.start_date),
        FormattingHelpers.to_date_string(assignment.end_date),
        status,
        pick_period
      ]
    ])
  end
end

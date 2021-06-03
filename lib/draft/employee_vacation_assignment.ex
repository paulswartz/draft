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
    :forced?
  ]

  @type t :: %__MODULE__{
          employee_id: String.t(),
          vacation_interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          forced?: boolean()
        }
  @spec to_csv_row(Draft.EmployeeVacationAssignment.t()) :: iodata()
  def to_csv_row(assignment) do
    PipeSeparatedParser.dump_to_iodata([
      [
        "vacation",
        assignment.employee_id,
        assignment.vacation_interval_type,
        FormattingHelpers.to_date_string(assignment.start_date),
        FormattingHelpers.to_date_string(assignment.end_date),
        # assume always vacation assigned, not cancelled
        1,
        # assuming given as part of quarterly pick
        1
      ]
    ])
  end
end

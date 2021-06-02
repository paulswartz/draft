defmodule Draft.EmployeeVacationAssignment do
  @moduledoc """
    Represents vacation time an employee has been assigned.
  """
  alias Draft.ParsingHelpers

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
        ParsingHelpers.to_date_string(assignment.start_date),
        ParsingHelpers.to_date_string(assignment.end_date),
        1,
        1
      ]
    ])
  end
end

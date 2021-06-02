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

  def to_parts(assignment) do
    "vacation|#{assignment.employee_id}|#{assignment.vacation_interval_type}|#{ParsingHelpers.to_date_string(assignment.start_date)}|#{ParsingHelpers.to_date_string(assignment.end_date)}|1|1\n"
  end
end

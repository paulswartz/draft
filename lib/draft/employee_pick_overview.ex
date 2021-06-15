defmodule Draft.EmployeePickOverview do
  @moduledoc """
  An overview of an employee's standing in a particular pick round.
  """
  import Ecto.Query
  alias Draft.Repo

  @type t :: %__MODULE__{
          employee_id: String.t(),
          cutoff_time: DateTime.t(),
          rank: integer()
        }

  defstruct [:cutoff_time, :employee_id, :rank]

  @spec get_latest(String.t()) :: Draft.EmployeePickOverview.t() | nil
  @doc """
  Get the pick overview from the latest pick that the employee with the given badge number is a part of.
  """
  def get_latest(badge_number) do
    Repo.one(
      from e in Draft.EmployeeRanking,
        join: g in Draft.BidGroup,
        on:
          e.group_number == g.group_number and g.process_id == e.process_id and
            g.round_id == e.round_id,
        where: e.employee_id == ^badge_number,
        order_by: [desc: g.cutoff_datetime],
        select: %Draft.EmployeePickOverview{
          cutoff_time: g.cutoff_datetime,
          employee_id: e.employee_id,
          rank: e.rank
        },
        limit: 1
    )
  end
end

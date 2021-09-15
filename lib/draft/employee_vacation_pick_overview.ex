defmodule Draft.EmployeeVacationPickOverview do
  @moduledoc """
  An overview of an employee's standing in a particular pick round.
  """
  import Ecto.Query
  alias Draft.Repo

  @type t :: %__MODULE__{
          division_id: String.t(),
          employee_id: String.t(),
          cutoff_time: DateTime.t(),
          job_class: String.t(),
          rank: integer(),
          process_id: String.t(),
          round_id: String.t(),
          interval_type: Draft.IntervalType.t(),
          amount_to_force: non_neg_integer() | nil
        }

  @derive {Jason.Encoder,
           only: [
             :process_id,
             :round_id,
             :interval_type,
             :cutoff_time,
             :rank,
             :employee_id,
             :amount_to_force
           ]}

  defstruct [
    :division_id,
    :employee_id,
    :cutoff_time,
    :job_class,
    :rank,
    :process_id,
    :round_id,
    :interval_type,
    :amount_to_force
  ]

  @spec open_round(String.t()) :: Draft.EmployeeVacationPickOverview.t() | nil
  @doc """
  Get an overview of an employee's standing in a currently active vacation pick, if
  any is ongoing.
  """
  def open_round(employee_id) do
    current_est_date =
      DateTime.utc_now()
      |> DateTime.shift_zone!("America/New_York")
      |> DateTime.to_date()

    overview =
      Repo.one(
        from e in Draft.EmployeeRanking,
          join: g in Draft.BidGroup,
          on:
            e.group_number == g.group_number and g.process_id == e.process_id and
              g.round_id == e.round_id,
          join: r in Draft.BidRound,
          on: g.round_id == r.round_id and g.process_id == r.process_id,
          where:
            r.bid_type == :vacation and e.employee_id == ^employee_id and
              r.round_opening_date <= ^current_est_date and
              r.round_closing_date >= ^current_est_date,
          order_by: [desc: g.cutoff_datetime],
          select: %Draft.EmployeeVacationPickOverview{
            cutoff_time: g.cutoff_datetime,
            employee_id: e.employee_id,
            rank: e.rank,
            division_id: r.division_id,
            job_class: e.job_class,
            round_id: r.round_id,
            process_id: r.process_id
          }
      )

    if overview do
      session = Draft.BidSession.vacation_session(overview)

      %{
        overview
        | interval_type: session.type_allowed,
          amount_to_force: Draft.PointOfEquivalence.amount_to_force_employee(session, employee_id)
      }
    end
  end
end

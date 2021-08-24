defmodule Draft.DivisionVacationWeekQuota do
  @moduledoc """
    Represents the division vacation quota for a given type of employee for a particular week
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.ParsingHelpers
  alias Draft.Repo

  @derive {Jason.Encoder, only: [:start_date, :end_date, :quota]}

  @type t :: %__MODULE__{
          division_id: String.t(),
          employee_selection_set: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          quota: integer(),
          is_restricted_week: boolean()
        }

  @primary_key false
  schema "division_vacation_week_quotas" do
    field :division_id, :string, primary_key: true
    field :employee_selection_set, :string, primary_key: true
    field :start_date, :date, primary_key: true
    field :end_date, :date
    field :quota, :integer
    field :is_restricted_week, :boolean

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      division_id,
      employee_selection_set,
      _week_number,
      start_date,
      end_date,
      _initial_quota,
      remaining_quota,
      is_restricted_week
    ] = row

    %__MODULE__{
      division_id: division_id,
      employee_selection_set: employee_selection_set,
      start_date: ParsingHelpers.to_date(start_date),
      end_date: ParsingHelpers.to_date(end_date),
      quota: ParsingHelpers.to_int(remaining_quota),
      is_restricted_week: is_restricted_week == "1"
    }
  end

  @spec remaining_quota(Draft.BidRound.t()) :: integer()
  @doc """
  Get the total remaining quota in the given round
  """
  def remaining_quota(round) do
    Draft.Repo.one!(
      from d in Draft.DivisionVacationWeekQuota,
        where:
          d.start_date >= ^round.rating_period_start_date and
            d.end_date <= ^round.rating_period_end_date,
        select: sum(d.quota)
    )
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(division_vacation_week_quota, attrs \\ %{}) do
    division_vacation_week_quota
    |> cast(attrs, [
      :division_id,
      :employee_selection_set,
      :start_date,
      :end_date,
      :quota,
      :is_restricted_week
    ])
    |> validate_required([
      :division_id,
      :employee_selection_set,
      :start_date,
      :end_date,
      :quota,
      :is_restricted_week
    ])
  end

  @spec all_available_weeks(String.t(), String.t(), String.t()) :: [Draft.DivisionWeekQuota]
  @doc """
  Get all vacation weeks that are available for an employee of the given job class in the specified round
  """
  def all_available_weeks(job_class, process_id, round_id) do
    %Draft.BidRound{
      rating_period_start_date: rating_period_start_date,
      rating_period_end_date: rating_period_end_date,
      division_id: division_id
    } =
      Repo.one!(
        from r in Draft.BidRound, where: r.round_id == ^round_id and r.process_id == ^process_id
      )

    selection_set = Draft.JobClassHelpers.get_selection_set(job_class)

    Repo.all(
      from w in Draft.DivisionVacationWeekQuota,
        where:
          w.division_id == ^division_id and w.quota > 0 and
            w.start_date <= ^rating_period_end_date and w.end_date >= ^rating_period_start_date and
            w.employee_selection_set == ^selection_set,
        order_by: [asc: w.start_date]
    )
  end

  @spec available_quota(Draft.BidRound.t(), %{
          required(:employee_id) => String.t(),
          required(:job_class) => String.t(),
          optional(atom()) => any()
        }) ::
          [t()]
  @doc """
  Get all vacation weeks that are available for the given employee, based on their job class, the available quota for their division,
  and their previously selected vacation time. Available weeks are returned in descending order by start date (latest available date will be listed first)
  """
  def available_quota(round, employee) do
    selection_set = Draft.JobClassHelpers.get_selection_set(employee.job_class)

    Repo.all(
      from w in Draft.DivisionVacationWeekQuota,
        as: :division_week_quota,
        where:
          w.division_id == ^round.division_id and w.quota > 0 and w.is_restricted_week == false and
            w.employee_selection_set == ^selection_set and
            ^round.rating_period_start_date <= w.start_date and
            ^round.rating_period_end_date >= w.end_date and
            not exists(conflicting_selected_vacation_query(employee.employee_id)),
        order_by: [desc: w.start_date]
    )
  end

  defp conflicting_selected_vacation_query(employee_id) do
    from s in Draft.EmployeeVacationSelection,
      where:
        s.start_date <= parent_as(:division_week_quota).end_date and
          s.end_date >= parent_as(:division_week_quota).start_date and
          s.employee_id == ^employee_id and
          s.status == :assigned
  end
end

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
  require Logger

  @derive {Jason.Encoder, only: [:start_date, :end_date, :quota]}

  @type t :: %__MODULE__{
          division_id: String.t(),
          employee_selection_set: String.t(),
          job_class_category: Draft.JobClassCategory.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          quota: integer(),
          is_restricted_week: boolean()
        }

  @primary_key false
  schema "division_vacation_week_quotas" do
    field :division_id, :string, primary_key: true
    field :employee_selection_set, :string, primary_key: true
    field :job_class_category, Draft.JobClassCategory
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
      job_class_category:
        Draft.JobClassCategory.from_hastus_division_quota(employee_selection_set),
      start_date: ParsingHelpers.to_date(start_date),
      end_date: ParsingHelpers.to_date(end_date),
      quota: ParsingHelpers.to_int(remaining_quota),
      is_restricted_week: is_restricted_week == "1"
    }
  end

  @spec remaining_quota(Draft.BidSession.t()) :: non_neg_integer()
  @doc """
  Get the amount of remaining quota in the given session.
  """
  def remaining_quota(session) do
    quotas =
      Draft.Repo.all(
        from d in Draft.DivisionVacationWeekQuota,
          where:
            d.start_date >= ^session.rating_period_start_date and
              d.end_date <= ^session.rating_period_end_date and
              d.division_id == ^session.division_id and
              d.job_class_category == ^session.job_class_category
      )

    quotas
    |> filter_cancelled_quotas(session.job_class_category)
    |> Enum.reduce(0, fn q, acc -> q.quota + acc end)
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

  @spec available_quota(
          Draft.BidSession.t(),
          String.t()
        ) ::
          [t()]
  @doc """
  Get all vacation weeks that are available for the given employee, based on the available quota for the division & job class category,
  and their previously selected vacation time. Available weeks are returned in descending order by start date (latest available date will be listed first)
  """
  def available_quota(session, employee_id) do
    quotas =
      Repo.all(
        from w in Draft.DivisionVacationWeekQuota,
          as: :division_week_quota,
          where:
            w.division_id == ^session.division_id and w.quota > 0 and
              w.is_restricted_week == false and
              w.job_class_category == ^session.job_class_category and
              ^session.rating_period_start_date <= w.start_date and
              ^session.rating_period_end_date >= w.end_date and
              not exists(conflicting_selected_vacation_query(employee_id)),
          order_by: [desc: w.start_date]
      )

    filter_cancelled_quotas(quotas, session.job_class_category)
  end

  defp conflicting_selected_vacation_query(employee_id) do
    from s in Draft.EmployeeVacationSelection,
      where:
        s.start_date <= parent_as(:division_week_quota).end_date and
          s.end_date >= parent_as(:division_week_quota).start_date and
          s.employee_id == ^employee_id and
          s.status == :assigned
  end

  @spec filter_cancelled_quotas([t()], Draft.JobClassCategory.t()) :: [t()]
  defp filter_cancelled_quotas([], _job_class_category) do
    []
  end

  defp filter_cancelled_quotas(quotas, job_class_category) do
    [d | _] = quotas
    %{start_date: start_date} = Enum.min_by(quotas, &Date.to_erl(&1.start_date))
    %{end_date: end_date} = Enum.max_by(quotas, &Date.to_erl(&1.end_date))

    cancelled_dates =
      Repo.all(
        from s in Draft.EmployeeVacationSelection,
          where:
            s.start_date >= ^start_date and s.end_date <= ^end_date and
              s.division_id == ^d.division_id and
              s.job_class in ^Draft.JobClassHelpers.job_classes_in_category(job_class_category) and
              s.vacation_interval_type == :week and
              s.status == :cancelled,
          select: [:start_date, :end_date]
      )

    cancelled_date_counts =
      cancelled_dates
      |> Enum.map(fn s -> {s.start_date, s.end_date} end)
      |> Enum.frequencies()

    for quota <- quotas,
        cancelled_count = Map.get(cancelled_date_counts, {quota.start_date, quota.end_date}, 0),
        quota.quota > cancelled_count do
      %{quota | quota: quota.quota - cancelled_count}
    end
  end
end

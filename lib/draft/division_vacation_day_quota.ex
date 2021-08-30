defmodule Draft.DivisionVacationDayQuota do
  @moduledoc """
    Represents the division vacation quota for a given type of employee for a particular day
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.ParsingHelpers
  alias Draft.Repo

  @derive {Jason.Encoder, only: [:date, :quota]}

  @type t :: %__MODULE__{
          division_id: String.t(),
          employee_selection_set: String.t(),
          job_class_category: Draft.JobClassCategory.t(),
          quota: integer(),
          date: Date.t()
        }

  @primary_key false
  schema "division_vacation_day_quotas" do
    field :division_id, :string, primary_key: true
    field :employee_selection_set, :string, primary_key: true
    field :job_class_category, Draft.JobClassCategory
    field :quota, :integer
    field :date, :date, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      division_id,
      employee_selection_set,
      date,
      _initial_quota,
      remaining_quota
    ] = row

    %__MODULE__{
      division_id: division_id,
      employee_selection_set: employee_selection_set,
      job_class_category:
        Draft.JobClassCategory.from_hastus_division_quota(employee_selection_set),
      date: ParsingHelpers.to_date(date),
      quota: ParsingHelpers.to_int(remaining_quota)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(division_vacation_quota_dated, attrs \\ %{}) do
    division_vacation_quota_dated
    |> cast(attrs, [:division_id, :employee_selection_set, :date, :quota])
    |> validate_required([:division_id, :employee_selection_set, :date, :quota])
  end

  @spec all_available_days(String.t(), String.t(), String.t()) :: [Draft.DivisionVacationDayQuota]
  @doc """
  Get all vacation days that are available for an employee of the given job class in the specified round
  """
  def all_available_days(job_class, process_id, round_id) do
    %Draft.BidRound{
      rating_period_start_date: rating_period_start_date,
      rating_period_end_date: rating_period_end_date,
      division_id: division_id
    } =
      Repo.one!(
        from r in Draft.BidRound, where: r.round_id == ^round_id and r.process_id == ^process_id
      )

    job_class_category = Draft.JobClassHelpers.job_category_for_class(job_class)

    Repo.all(
      from d in Draft.DivisionVacationDayQuota,
        where:
          d.division_id == ^division_id and d.quota > 0 and
            d.date >= ^rating_period_start_date and d.date <= ^rating_period_end_date and
            d.job_class_category == ^job_class_category,
        order_by: [asc: d.date]
    )
  end

  @spec available_quota(
          Draft.BidSession.t(),
          %{
            required(:employee_id) => String.t(),
            required(:job_class) => String.t(),
            optional(atom()) => any()
          }
        ) :: [t()]
  @doc """
  Get all vacation days that are available for the given employee, based on their job class, the available quota for their division,
  and their previously selected vacation time. Available days are returned in descending order by start date (latest available date will be listed first)
  """
  def available_quota(session, employee) do
    job_class_category = Draft.JobClassHelpers.job_category_for_class(employee.job_class)

    quotas =
      Repo.all(
        from d in Draft.DivisionVacationDayQuota,
          as: :division_day_quota,
          where:
            d.division_id == ^session.division_id and d.quota > 0 and
              d.job_class_category == ^job_class_category and
              d.date >= ^session.rating_period_start_date and
              d.date <= ^session.rating_period_end_date and
              not exists(conflicting_selected_dates_for_employee(employee)),
          order_by: [desc: d.date]
      )

    filter_cancelled_quotas(quotas, job_class_category)
  end

  @spec conflicting_selected_dates_for_employee(Draft.EmployeeRanking.t()) :: Ecto.Queryable.t()
  defp conflicting_selected_dates_for_employee(employee) do
    from s in Draft.EmployeeVacationSelection,
      where:
        s.start_date <= parent_as(:division_day_quota).date and
          s.end_date >= parent_as(:division_day_quota).date and
          s.employee_id == ^employee.employee_id and
          s.status == :assigned
  end

  @spec filter_cancelled_quotas([t()], Draft.JobClassCategory.t()) :: [
          t()
        ]
  defp filter_cancelled_quotas([], _job_class_category) do
    []
  end

  defp filter_cancelled_quotas(quotas, job_class_category) do
    [d | _] = quotas
    {%{date: start_date}, %{date: end_date}} = Enum.min_max_by(quotas, &Date.to_erl(&1.date))

    cancelled_dates =
      Repo.all(
        from s in Draft.EmployeeVacationSelection,
          where:
            s.start_date >= ^start_date and s.end_date <= ^end_date and
              s.division_id == ^d.division_id and
              s.job_class in ^Draft.JobClassHelpers.job_classes_in_category(job_class_category) and
              s.vacation_interval_type == :day and
              s.status == :cancelled,
          select: [:start_date, :end_date]
      )

    cancelled_date_counts =
      cancelled_dates
      |> Enum.flat_map(fn s -> Date.range(s.start_date, s.end_date) end)
      |> Enum.frequencies()

    for quota <- quotas,
        cancelled_count = Map.get(cancelled_date_counts, quota.date, 0),
        quota.quota > cancelled_count do
      %{quota | quota: quota.quota - cancelled_count}
    end
  end
end

defmodule Draft.EmployeeVacationQuota do
  @moduledoc """
    Represents the vacation time available to a specific employee for the given interval.
    Note: the quotas available after the "availabe_after_date" are included in the regular weekly & dated quotas.
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          employee_id: String.t(),
          interval_start_date: Date.t(),
          interval_end_date: Date.t(),
          weekly_quota: integer(),
          dated_quota: integer(),
          restricted_week_quota: integer() | nil,
          available_after_date: Date.t() | nil,
          available_after_dated_quota: integer() | nil,
          available_after_weekly_quota: integer() | nil,
          maximum_minutes: integer()
        }

  @primary_key false
  schema "employee_vacation_quotas" do
    field :employee_id, :string
    field :interval_start_date, :date
    field :interval_end_date, :date
    field :weekly_quota, :integer
    field :dated_quota, :integer
    field :restricted_week_quota, :integer
    field :available_after_date, :date
    field :available_after_dated_quota, :integer
    field :available_after_weekly_quota, :integer
    field :maximum_minutes, :integer

    timestamps()
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      interval_start_date,
      interval_end_date,
      weekly_quota,
      dated_quota,
      restricted_week_quota,
      available_after_date,
      available_after_weekly_quota,
      available_after_dated_quota,
      maximum_minutes
    ] = row

    %__MODULE__{
      employee_id: employee_id,
      interval_start_date: ParsingHelpers.to_date(interval_start_date),
      interval_end_date: ParsingHelpers.to_date(interval_end_date),
      weekly_quota: String.to_integer(weekly_quota),
      dated_quota: String.to_integer(dated_quota),
      restricted_week_quota: ParsingHelpers.to_int(restricted_week_quota),
      available_after_date: ParsingHelpers.to_optional_date(available_after_date),
      available_after_weekly_quota:
        ParsingHelpers.to_int(available_after_weekly_quota),
      available_after_dated_quota: ParsingHelpers.to_int(available_after_dated_quota),
      maximum_minutes: ParsingHelpers.to_minutes(maximum_minutes)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_quota, attrs \\ %{}) do
    employee_vacation_quota
    |> cast(attrs, [
      :employee_id,
      :interval_start_date,
      :interval_end_date,
      :weekly_quota,
      :dated_quota,
      :restricted_week_quota,
      :available_after_date,
      :available_after_weekly_quota,
      :available_after_dated_quota,
      :maximum_minutes
    ])
    |> validate_required([
      :employee_id,
      :interval_start_date,
      :interval_end_date,
      :weekly_quota,
      :dated_quota,
      :restricted_week_quota,
      :available_after_date,
      :available_after_weekly_quota,
      :available_after_dated_quota,
      :maximum_minutes
    ])
  end
end

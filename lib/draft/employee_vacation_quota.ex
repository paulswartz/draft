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
          quota_interval_start_date: Date.t(),
          quota_interval_end_date: Date.t(),
          weekly_quota_value: integer(),
          dated_quota_value: integer(),
          restricted_week_quota_value: integer() | nil,
          available_after_date: Date.t() | nil,
          available_after_dated_quota_value: integer() | nil,
          available_after_weekly_quota_value: integer() | nil,
          maximum_minutes: integer()
        }

  @primary_key false
  schema "employee_vacation_quotas" do
    field :employee_id, :string
    field :quota_interval_start_date, :date
    field :quota_interval_end_date, :date
    field :weekly_quota_value, :integer
    field :dated_quota_value, :integer
    field :restricted_week_quota_value, :integer
    field :available_after_date, :date
    field :available_after_dated_quota_value, :integer
    field :available_after_weekly_quota_value, :integer
    field :maximum_minutes, :integer

    timestamps()
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      quota_interval_start_date,
      quota_interval_end_date,
      weekly_quota_value,
      dated_quota_value,
      restricted_week_quota_value,
      available_after_date,
      available_after_weekly_quota_value,
      available_after_dated_quota_value,
      maximum_minutes
    ] = row

    %__MODULE__{
      employee_id: employee_id,
      quota_interval_start_date: ParsingHelpers.to_date(quota_interval_start_date),
      quota_interval_end_date: ParsingHelpers.to_date(quota_interval_end_date),
      weekly_quota_value: String.to_integer(weekly_quota_value),
      dated_quota_value: String.to_integer(dated_quota_value),
      restricted_week_quota_value: ParsingHelpers.to_optional_int(restricted_week_quota_value),
      available_after_date: ParsingHelpers.to_optional_date(available_after_date),
      available_after_weekly_quota_value:
        ParsingHelpers.to_optional_int(available_after_weekly_quota_value),
      available_after_dated_quota_value:
        ParsingHelpers.to_optional_int(available_after_dated_quota_value),
      maximum_minutes: ParsingHelpers.to_minutes(maximum_minutes)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_quota, attrs \\ %{}) do
    employee_vacation_quota
    |> cast(attrs, [
      :employee_id,
      :quota_interval_start_date,
      :quota_interval_end_date,
      :weekly_quota_value,
      :dated_quota_value,
      :restricted_week_quota_value,
      :available_after_date,
      :available_after_weekly_quota_value,
      :available_after_dated_quota_value,
      :maximum_minutes
    ])
    |> validate_required([
      :employee_id,
      :quota_interval_start_date,
      :quota_interval_end_date,
      :weekly_quota_value,
      :dated_quota_value,
      :restricted_week_quota_value,
      :available_after_date,
      :available_after_weekly_quota_value,
      :available_after_dated_quota_value,
      :maximum_minutes
    ])
  end
end

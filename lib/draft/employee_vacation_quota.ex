defmodule Draft.EmployeeVacationQuota do
  @moduledoc """
    Represents the vacation time available to a specific employee for the given interval.
    Note: the quotas available after the "availabe_after_date" are included in the regular weekly & dated quotas.
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          employee_id: String.t(),
          interval_start_date: Date.t(),
          interval_end_date: Date.t(),
          weekly_quota: integer(),
          dated_quota: integer(),
          restricted_week_quota: integer(),
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

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      interval_start_date,
      interval_end_date,
      weekly_quota,
      # Value not accurate from HASTUS export yet
      _remaining_weekly_quota,
      dated_quota,
      # Value not accurate from HASTUS export yet
      _remaining_dated_quota,
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
      available_after_weekly_quota: ParsingHelpers.to_int(available_after_weekly_quota),
      available_after_dated_quota: ParsingHelpers.to_int(available_after_dated_quota),
      maximum_minutes: ParsingHelpers.to_minutes(maximum_minutes)
    }
  end

  @spec quota_covering_interval(
          String.t(),
          Date.t(),
          Date.t()
        ) :: t()
  @doc """
  Get an employee's vacation quota covering the entire date range given.
  """
  def quota_covering_interval(
        employee_id,
        start_date,
        end_date
      ) do
    Draft.Repo.one!(
      from q in __MODULE__,
        where:
          q.employee_id == ^employee_id and
            (q.interval_start_date <= ^start_date and
               q.interval_end_date >= ^end_date)
    )
  end

  @spec get_anniversary_quota(t()) ::
          nil
          | %{
              anniversary_date: Date.t(),
              anniversary_weeks: integer(),
              anniversary_days: integer()
            }
  @doc """
  Get the anniversary quota that is awarded during the given employee vacation balance interval,
  if there is an anniversary during that time.
  """
  def get_anniversary_quota(employee_balance)

  def get_anniversary_quota(employee_balance)
      when is_nil(employee_balance.available_after_date) do
    nil
  end

  def get_anniversary_quota(employee_balance) do
    %{
      anniversary_date: employee_balance.available_after_date,
      anniversary_weeks: employee_balance.available_after_weekly_quota,
      anniversary_days: employee_balance.available_after_dated_quota
    }
  end

  @spec adjust_quota(integer(), integer()) :: non_neg_integer()
  @doc """
  The vacation quotas given by HASTUS (weekly_quota, dated_quota) include any weeks / days that are only available on and after an anniversary date.
  This function returns the initial quota less the quota given to subtract. The lowest possible quota returned is zero; quota cannot be negative.
  """
  def adjust_quota(
        initial_quota,
        quota_to_subtract
      ) do
    max(initial_quota - quota_to_subtract, 0)
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

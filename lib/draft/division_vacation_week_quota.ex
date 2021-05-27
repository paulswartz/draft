defmodule Draft.DivisionVacationWeekQuota do
  @moduledoc """
    Represents the division vacation quota for a given type of employee for a particular week
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

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
    field :division_id, :string
    field :employee_selection_set, :string
    field :start_date, :date
    field :end_date, :date
    field :quota, :integer
    field :is_restricted_week, :boolean

    timestamps()
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      division_id,
      employee_selection_set,
      _week_number,
      start_date,
      end_date,
      quota,
      is_restricted_week
    ] = row

    %__MODULE__{
      division_id: division_id,
      employee_selection_set: employee_selection_set,
      start_date: ParsingHelpers.to_date(start_date),
      end_date: ParsingHelpers.to_date(end_date),
      quota: ParsingHelpers.to_int(quota),
      is_restricted_week: is_restricted_week == "1"
    }
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
end

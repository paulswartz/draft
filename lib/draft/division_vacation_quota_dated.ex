defmodule Draft.DivisionVacationQuotaDated do
  @moduledoc """
    Represents the division vacation quota for a given type of employee for a particular day
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          division_id: String.t(),
          employee_selection_set: String.t(),
          quota_value: integer(),
          vacation_date: Date.t()
        }

  @primary_key false
  schema "division_vacation_quota_days" do
    field :division_id, :string
    field :employee_selection_set, :string
    field :quota_value, :integer
    field :vacation_date, :date

    timestamps()
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      division_id,
      employee_selection_set,
      vacation_date,
      quota_value
    ] = row

    %__MODULE__{
      division_id: division_id,
      employee_selection_set: employee_selection_set,
      vacation_date: ParsingHelpers.to_date(vacation_date),
      quota_value: String.to_integer(quota_value)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(division_vacation_quota_dated, attrs \\ %{}) do
    division_vacation_quota_dated
    |> cast(attrs, [:division_id, :employee_selection_set, :vacation_date, :quota_value])
    |> validate_required([:division_id, :employee_selection_set, :vacation_date, :quota_value])
  end
end

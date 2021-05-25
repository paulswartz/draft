defmodule Draft.EmployeeVacationSelection do
  @moduledoc """
    Represents vacation time an employee has selected.
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          employee_id: String.t(),
          vacation_interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          pick_period: String.t()
        }

  @primary_key false
  schema "employee_vacation_selections" do
    field :employee_id, :string
    field :vacation_interval_type, :string
    field :start_date, :date
    field :end_date, :date
    field :pick_period, :string

    timestamps()
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      vacation_interval_type,
      start_date,
      end_date,
      pick_period
    ] = row

    %__MODULE__{
      employee_id: employee_id,
      vacation_interval_type: vacation_interval_type,
      start_date: ParsingHelpers.to_date(start_date),
      end_date: ParsingHelpers.to_date(end_date),
      pick_period: pick_period
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_selection, attrs \\ %{}) do
    employee_vacation_selection
    |> cast(attrs, [:employee_id, :vacation_interval_type, :start_date, :end_date, :pick_period])
    |> validate_required([
      :employee_id,
      :vacation_interval_type,
      :start_date,
      :end_date,
      :pick_period
    ])
  end
end

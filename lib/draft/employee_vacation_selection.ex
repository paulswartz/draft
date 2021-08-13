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
          vacation_interval_type: Draft.IntervalType.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          status: Draft.VacationStatusEnum.t(),
          pick_period: String.t(),
          division_id: String.t(),
          job_class: String.t()
        }

  @primary_key false
  schema "employee_vacation_selections" do
    field :employee_id, :string
    field :vacation_interval_type, Draft.IntervalType
    field :start_date, :date
    field :end_date, :date
    field :status, Draft.VacationStatusEnum
    field :pick_period, :string
    field :division_id, :string
    field :job_class, :string

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      vacation_interval_type,
      start_date,
      end_date,
      status,
      pick_period,
      division_id,
      job_class
    ] = row

    %__MODULE__{
      employee_id: employee_id,
      vacation_interval_type:
        if vacation_interval_type == "Weekly" do
          :week
        else
          :day
        end,
      start_date: ParsingHelpers.to_date(start_date),
      end_date: ParsingHelpers.to_date(end_date),
      status:
        if status == "Effective" do
          :assigned
        else
          :cancelled
        end,
      pick_period: pick_period,
      division_id: division_id,
      job_class: job_class
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_selection, attrs \\ %{}) do
    employee_vacation_selection
    |> cast(attrs, [
      :employee_id,
      :vacation_interval_type,
      :start_date,
      :end_date,
      :pick_period,
      :status,
      :division_id,
      :job_class
    ])
    |> validate_required([
      :employee_id,
      :vacation_interval_type,
      :start_date,
      :end_date,
      :status,
      :pick_period,
      :division_id,
      :job_class
    ])
  end
end

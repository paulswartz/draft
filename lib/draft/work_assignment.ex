defmodule Draft.WorkAssignment do
  @moduledoc """
  Represents the work that an operator is doing on a particular day
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          assignment: String.t(),
          employee_id: String.t(),
          hours_worked: integer(),
          internal_duty_id: String.t(),
          is_dated_exception: boolean(),
          is_from_primary_pick: boolean(),
          is_vr: boolean(),
          division_id: String.t(),
          job_class: String.t(),
          operating_date: Date.t(),
          roster_set_internal_id: integer()
        }

  schema "work_assignments" do
    field :assignment, :string
    field :employee_id, :string
    field :hours_worked, :integer
    field :internal_duty_id, :string
    field :is_dated_exception, :boolean
    field :is_from_primary_pick, :boolean
    field :is_vr, :boolean
    field :division_id, :string
    field :job_class, :string
    field :operating_date, :date
    field :roster_set_internal_id, :integer

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      employee_id,
      is_dated_exception,
      operating_date,
      is_vr,
      _employee_record_number,
      _employee_start_date,
      division_id,
      _start_date_of_roster_set,
      _end_date_of_roster_set,
      job_class,
      assignment,
      internal_duty_id,
      _operating_days
    ] = row

    %__MODULE__{
      employee_id: employee_id,
      is_dated_exception: Draft.ParsingHelpers.to_boolean(is_dated_exception),
      operating_date: Draft.ParsingHelpers.to_date(operating_date),
      is_vr: Draft.ParsingHelpers.to_boolean(is_vr),
      division_id: division_id,
      job_class: job_class,
      # These values would be comma separated in the case of trippers.
      # Can assume the first listed is the primary duty.
      assignment: List.first(String.split(assignment, ",")),
      internal_duty_id: List.first(String.split(internal_duty_id, ","))
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(work_assignment, attrs) do
    work_assignment
    |> cast(attrs, [
      :employee_id,
      :is_dated_exception,
      :operating_date,
      :is_vr,
      :division_id,
      :roster_set_internal_id,
      :is_from_primary_pick,
      :assignment,
      :internal_duty_id,
      :hours_worked
    ])
    |> validate_required([
      :employee_id,
      :is_dated_exception,
      :operating_date,
      :is_vr,
      :division_id,
      :roster_set_internal_id,
      :is_from_primary_pick,
      :assignment,
      :internal_duty_id,
      :hours_worked
    ])
  end
end

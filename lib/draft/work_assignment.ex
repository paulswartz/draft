defmodule Draft.WorkAssignment do
  @moduledoc """
  Represents the work that an operator is doing on a particular day.
  The `hours_worked` field can be nil in the case where we don't yet know an
  operator's assignment on a particular day -- for example, if they have chosen
  to work VR, but have not yet chosen
  """
  @behaviour Draft.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @type t :: %__MODULE__{
          assignment: String.t(),
          employee_id: String.t(),
          hours_worked: integer() | nil,
          duty_internal_id: integer() | nil,
          is_dated_exception: boolean(),
          is_from_primary_pick: boolean(),
          is_vr: boolean(),
          division_id: String.t(),
          job_class: String.t(),
          operating_date: Date.t(),
          roster_set_internal_id: integer()
        }

  @primary_key false
  schema "work_assignments" do
    field :assignment, :string
    field :employee_id, :string, primary_key: true
    field :hours_worked, :integer
    field :duty_internal_id, :integer
    field :is_dated_exception, :boolean
    field :is_from_primary_pick, :boolean
    field :is_vr, :boolean
    field :division_id, :string
    field :job_class, :string
    field :operating_date, :date, primary_key: true
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
      roster_set_internal_id,
      is_from_primary_pick,
      _start_date_of_roster_set,
      _end_date_of_roster_set,
      job_class,
      assignment,
      duty_internal_id,
      _operating_days
    ] = row

    assignment_from_file = %__MODULE__{
      employee_id: employee_id,
      is_dated_exception: Draft.ParsingHelpers.to_boolean(is_dated_exception),
      operating_date: Draft.ParsingHelpers.to_date(operating_date),
      is_vr: Draft.ParsingHelpers.to_boolean(is_vr),
      division_id: division_id,
      roster_set_internal_id: String.to_integer(roster_set_internal_id),
      is_from_primary_pick: Draft.ParsingHelpers.to_boolean(is_from_primary_pick),
      job_class: job_class,
      # These values would be comma separated in the case of trippers.
      # Can assume the first listed is the primary duty.
      assignment: List.first(String.split(assignment, ",", parts: 2)),
      duty_internal_id:
        duty_internal_id
        |> String.split(",", parts: 2)
        |> List.first()
        |> Draft.ParsingHelpers.to_optional_integer()
    }

    %{assignment_from_file | hours_worked: hours_worked(assignment_from_file)}
  end

  @spec hours_worked(Draft.WorkAssignment.t()) :: integer() | nil
  defp hours_worked(%Draft.WorkAssignment{assignment: "OFF"}) do
    0
  end

  defp hours_worked(%Draft.WorkAssignment{
         assignment: assignment,
         duty_internal_id: nil,
         job_class: job_class
       }) do
    hours_worked_pending_assignment(assignment, Draft.JobClassHelpers.pt_or_ft(job_class))
  end

  defp hours_worked(%Draft.WorkAssignment{
         duty_internal_id: duty_internal_id,
         roster_set_internal_id: roster_set_internal_id,
         job_class: job_class,
         operating_date: date
       }) do
    work_off_ratio =
      Draft.RosterDay.work_off_ratio_for_duty(roster_set_internal_id, duty_internal_id, date)

    Draft.JobClassHelpers.num_hours_per_day(job_class, work_off_ratio)
  end

  defp hours_worked_pending_assignment(assignment, :pt) do
    case assignment do
      "VRP" -> 6
      "OLP" -> 6
      "LRP" -> 6
    end
  end

  defp hours_worked_pending_assignment(assignment, :ft) do
    case assignment do
      "VR" -> nil
      "OL" -> nil
      "LR08" -> 8
      "LR" -> 8
      "LR10" -> 10
    end
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
      :duty_internal_id,
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
      :duty_internal_id,
      :hours_worked
    ])
  end

  @spec delete_all_records_for_divisions([String.t()]) :: {integer(), nil | [term()]}
  @doc """
  Delete all work assignments in the given divisions.
  """
  def delete_all_records_for_divisions(division_ids) do
    Draft.Repo.delete_all(from w in __MODULE__, where: w.division_id in ^division_ids)
  end
end

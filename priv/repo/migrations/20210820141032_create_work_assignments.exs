defmodule Draft.Repo.Migrations.CreateWorkAssignments do
  use Ecto.Migration

  def change do
    create table(:work_assignments) do
      add :employee_id, :string
      add :is_dated_exception, :boolean
      add :operating_date, :date
      add :is_vr, :boolean
      add :division_id, :string
      add :roster_set_internal_id, :integer
      add :is_from_primary_pick, :boolean
      add :job_class, :string
      add :assignment, :string
      add :internal_duty_id, :string
      add :hours_worked, :integer

      timestamps(type: :timestamptz)
    end
  end
end

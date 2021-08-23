defmodule Draft.Repo.Migrations.CreateWorkAssignments do
  use Ecto.Migration

  def change do
    create table(:work_assignments, primary_key: false) do
      add :employee_id, :string, primary_key: true
      add :is_dated_exception, :boolean
      add :operating_date, :date, primary_key: true
      add :is_vr, :boolean
      add :division_id, :string
      add :roster_set_internal_id, :integer
      add :is_from_primary_pick, :boolean
      add :job_class, :string
      add :assignment, :string
      add :duty_internal_id, :integer
      add :hours_worked, :integer

      timestamps(type: :timestamptz)
    end
  end
end

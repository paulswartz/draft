defmodule Draft.Repo.Migrations.CreateEmployeeVacationPreferenceSets do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_preference_sets) do
      add :employee_id, :string
      add :process_id, :string

      add :round_id,
          references(:employee_rankings,
            column: :round_id,
            type: :string,
            with: [process_id: :process_id, employee_id: :employee_id]
          )

      add :previous_preference_set_id, :integer

      timestamps(type: :timestamptz)
    end
  end
end

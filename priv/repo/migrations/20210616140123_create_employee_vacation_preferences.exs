defmodule Draft.Repo.Migrations.CreateEmployeeVacationPreferences do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_preferences) do
      add :preference_set_id, references("employee_vacation_preference_sets")
      add :interval_type, :string
      add :start_date, :date
      add :end_date, :date
      add :preference_rank, :integer

      timestamps(type: :timestamptz)
    end

    create unique_index("employee_vacation_preferences", [:preference_set_id, :interval_type, :start_date], name: :vacation_preference_interval_date_index)

    create unique_index("employee_vacation_preferences", [:preference_set_id, :interval_type, :preference_rank], name: :vacation_preference_interval_rank_index)

  end
end

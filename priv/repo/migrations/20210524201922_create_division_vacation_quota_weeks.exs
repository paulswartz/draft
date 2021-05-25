defmodule Draft.Repo.Migrations.CreateDivisionVacationQuotaWeeks do
  use Ecto.Migration

  def change do
    create table(:division_vacation_quota_weeks, primary_key: false) do
      add :division_id, :string
      add :employee_selection_set, :string
      add :start_date, :date
      add :end_date, :date
      add :quota_value, :integer
      add :is_restricted_week, :boolean, default: false, null: false

      timestamps()
    end
  end
end

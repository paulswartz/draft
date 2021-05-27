defmodule Draft.Repo.Migrations.CreateDivisionVacationQuotaWeeks do
  use Ecto.Migration

  def change do
    create table(:division_vacation_quota_weeks, primary_key: false) do
      add :division_id, :string, primary_key: true
      add :employee_selection_set, :string, primary_key: true
      add :start_date, :date, primary_key: true
      add :end_date, :date
      add :quota, :integer
      add :is_restricted_week, :boolean

      timestamps()
    end
  end
end

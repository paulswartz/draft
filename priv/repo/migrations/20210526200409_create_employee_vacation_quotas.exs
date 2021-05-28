defmodule Draft.Repo.Migrations.CreateEmployeeVacationQuotas do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_quotas, primary_key: false) do
      add :employee_id, :string, primary_key: true
      add :interval_start_date, :date, primary_key: true
      add :interval_end_date, :date
      add :weekly_quota, :integer
      add :dated_quota, :integer
      add :restricted_week_quota, :integer
      add :available_after_date, :date
      add :available_after_weekly_quota, :integer
      add :available_after_dated_quota, :integer
      add :maximum_minutes, :integer

      timestamps()
    end
  end
end

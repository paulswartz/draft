defmodule Draft.Repo.Migrations.CreateEmployeeVacationQuotas do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_quotas, primary_key: false) do
      add :employee_id, :string
      add :quota_interval_start_date, :date
      add :quota_interval_end_date, :date
      add :weekly_quota_value, :integer
      add :dated_quota_value, :integer
      add :restricted_week_quota_value, :integer
      add :available_after_date, :date
      add :available_after_weekly_quota_value, :integer
      add :available_after_dated_quota_value, :integer
      add :maximum_minutes, :integer

      timestamps()
    end
  end
end

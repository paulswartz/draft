defmodule Draft.Repo.Migrations.CreateEmployeeVacationSelections do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_selections, primary_key: false) do
      add :employee_id, :string, primary_key: true
      add :vacation_interval_type, :string, primary_key: true
      add :start_date, :date, primary_key: true
      add :end_date, :date
      add :pick_period, :string

      timestamps()
    end
  end
end

defmodule Draft.Repo.Migrations.CreateEmployeeVacationSelections do
  use Ecto.Migration

  def change do
    create table(:employee_vacation_selections, primary_key: false) do
      add :employee_id, :string
      add :vacation_interval_type, :string
      add :start_date, :date
      add :end_date, :date
      add :pick_period, :string

      timestamps()
    end
  end
end

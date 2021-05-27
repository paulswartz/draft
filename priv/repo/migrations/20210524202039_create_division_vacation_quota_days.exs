defmodule Draft.Repo.Migrations.CreateDivisionVacationQuotaDays do
  use Ecto.Migration

  def change do
    create table(:division_vacation_quota_days, primary_key: false) do
      add :division_id, :string, primary_key: true
      add :employee_selection_set, :string, primary_key: true
      add :date, :date, primary_key: true
      add :quota, :integer

      timestamps()
    end
  end
end

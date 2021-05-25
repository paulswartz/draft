defmodule Draft.Repo.Migrations.CreateDivisionVacationQuotaDays do
  use Ecto.Migration

  def change do
    create table(:division_vacation_quota_days, primary_key: false) do
      add :division_id, :string
      add :employee_selection_set, :string
      add :vacation_date, :date
      add :quota_value, :integer

      timestamps()
    end
  end
end

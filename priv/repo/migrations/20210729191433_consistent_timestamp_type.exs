defmodule Draft.Repo.Migrations.ConsistentTimestampType do
  use Ecto.Migration

  def change do
    alter table(:division_vacation_week_quotas) do
      modify :inserted_at, :timestamptz
      modify :updated_at, :timestamptz
    end

    alter table(:division_vacation_day_quotas) do
      modify :inserted_at, :timestamptz
      modify :updated_at, :timestamptz
    end

    alter table(:employee_vacation_quotas) do
      modify :inserted_at, :timestamptz
      modify :updated_at, :timestamptz
    end

    alter table(:employee_vacation_selections) do
      modify :inserted_at, :timestamptz
      modify :updated_at, :timestamptz
    end
  end
end

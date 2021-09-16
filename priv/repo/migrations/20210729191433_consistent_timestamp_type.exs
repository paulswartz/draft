defmodule Draft.Repo.Migrations.ConsistentTimestampType do
  use Ecto.Migration

  def up do
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

  def down do
    alter table(:division_vacation_week_quotas) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:division_vacation_day_quotas) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:employee_vacation_quotas) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:employee_vacation_selections) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end
  end
end

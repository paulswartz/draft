defmodule Draft.Repo.Migrations.AddJobClassCategory do
  use Ecto.Migration

  def change do
    alter table(:division_vacation_week_quotas) do
      add :job_class_category, :string
    end

    alter table(:division_vacation_day_quotas) do
      add :job_class_category, :string
    end
  end
end

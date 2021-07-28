defmodule Draft.Repo.Migrations.AddVacSelectionFields do
  use Ecto.Migration

  def change do
    alter table(:employee_vacation_selections) do
      add :status, :integer
      add :division_id, :string
      add :job_class, :string
    end
  end
end

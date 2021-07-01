defmodule Draft.Repo.Migrations.CreateVacationDistributions do
  use Ecto.Migration

  def change do
    create table(:vacation_distributions) do
      add :run_id, references("vacation_distribution_runs")
      add :employee_id, :string
      add :interval_type, :string
      add :start_date, :date
      add :end_date, :date
      add :status, :integer
      add :rolled_back, :boolean, default: false, null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(
             "vacation_distributions",
             [:run_id, :employee_id, :start_date, :end_date],
             name: :unique_distribution_in_run
           )
  end
end

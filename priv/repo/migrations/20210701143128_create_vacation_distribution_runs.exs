defmodule Draft.Repo.Migrations.CreateVacationDistributionRuns do
  use Ecto.Migration

  def change do
    create table(:vacation_distribution_runs) do
      add :process_id, :string
      add :round_id, :string
      add :start_time, :timestamptz
      add :end_time, :timestamptz

      timestamps(type: :timestamptz)
    end
  end
end

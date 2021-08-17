defmodule Draft.Repo.Migrations.AddVacationDistributionCols do
  use Ecto.Migration

  def change do
    alter table(:vacation_distributions) do
      add :preference_rank, :integer
      add :is_forced, :boolean
    end
  end
end

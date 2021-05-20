defmodule Draft.Repo.Migrations.CreateEmployeeRankings do
  use Ecto.Migration

  def change do
    create table(:employee_rankings) do
      add :process_id, :string
      add :round_id, :string
      add :group_number, :integer
      add :rank, :integer
      add :employee_id, :string
      add :name, :string
      add :job_class, :string

      timestamps()
    end

  end
end

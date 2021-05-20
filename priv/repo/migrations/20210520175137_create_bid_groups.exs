defmodule Draft.Repo.Migrations.CreateBidGroups do
  use Ecto.Migration

  def change do
    create table(:bid_groups) do
      add :process_id, :string
      add :round_id, :string
      add :group_number, :integer
      add :cutoff_datetime, :utc_datetime

      timestamps()
    end

  end
end

defmodule Draft.Repo.Migrations.CreateBidGroups do
  use Ecto.Migration

  def change do
    create table(:bid_groups, primary_key: false) do
      add :process_id, :string
      add :round_id, :string
      add :group_number, :integer
      add :cutoff_datetime, :utc_datetime

      timestamps(type: :timestamptz)
    end
    create unique_index(:bid_groups, [:process_id, :round_id, :group_number])
  end
end

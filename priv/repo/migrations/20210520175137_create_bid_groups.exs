defmodule Draft.Repo.Migrations.CreateBidGroups do
  use Ecto.Migration

  def change do
    create table(:bid_groups, primary_key: false) do
      add :process_id, :string, primary_key: true

      add :round_id,
        references(:bid_rounds,
          column: :round_id,
          on_delete: :delete_all,
          type: :string,
          with: [process_id: :process_id]
        ), primary_key: true


      add :group_number, :integer, primary_key: true
      add :cutoff_datetime, :timestamptz

      timestamps(type: :timestamptz)
    end

    create unique_index(:bid_groups, [:process_id, :round_id, :group_number])
  end
end

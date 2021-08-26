defmodule Draft.Repo.Migrations.CreateRosterSets do
  use Ecto.Migration

  def change do
    create table(:roster_sets, primary_key: false) do
      add :booking_id, :string, primary_key: true
      add :scheduling_unit, :string

      add :session_id,
          references(:bid_sessions,
            column: :session_id,
            on_delete: :delete_all,
            type: :string,
            with: [booking_id: :booking_id, scheduling_unit: :scheduling_unit]
          ),
          primary_key: true

      add :roster_set_id, :string
      add :roster_set_internal_id, :integer, primary_key: true
      add :scenario, :integer
      add :service_context, :string

      timestamps(type: :timestamptz)
    end
  end
end

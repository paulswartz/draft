defmodule Draft.Repo.Migrations.CreateRosterAvailabilities do
  use Ecto.Migration

  def change do
    create table(:roster_availabilities, primary_key: false) do
      add :booking_id, :string, primary_key: true
      add :session_id, :string, primary_key: true
      add :roster_set_id, :string

      add :roster_set_internal_id,
          references(:roster_sets,
            column: :roster_set_internal_id,
            on_delete: :delete_all,
            type: :integer,
            with: [booking_id: :booking_id, session_id: :session_id]
          ),
          primary_key: true

      add :roster_id, :string, primary_key: true
      add :work_off_ratio, :string
      add :is_available, :boolean

      timestamps(type: :timestamptz)
    end
  end
end

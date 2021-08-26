defmodule Draft.Repo.Migrations.CreateRosterDays do
  use Ecto.Migration

  def change do
    create table(:roster_days, primary_key: false) do
      add :booking_id, :string, primary_key: true
      add :roster_set_id, :string
      add :roster_set_internal_id, :integer, primary_key: true
      add :roster_id, :string, primary_key: true
      add :roster_position_id, :string
      add :roster_position_internal_id, :integer, primary_key: true
      add :day, :string, primary_key: true
      add :assignment, :string
      add :duty_internal_id, :integer
      add :crew_schedule_internal_id, :integer

      timestamps(type: :timestamptz)
    end
  end
end

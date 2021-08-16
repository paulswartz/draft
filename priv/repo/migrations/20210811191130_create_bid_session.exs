defmodule Draft.Repo.Migrations.CreateBidSession do
  use Ecto.Migration

  def change do
    create table(:bid_sessions, primary_key: false) do
      add :process_id, :string, primary_key: true

      add :round_id,
          references(:bid_rounds,
            column: :round_id,
            on_delete: :delete_all,
            type: :string,
            with: [process_id: :process_id]
          ),
          primary_key: true

      add :session_id, :string, primary_key: true
      add :booking_id, :string

      add :type, :string
      add :type_allowed, :string
      add :service_context, :string
      add :scheduling_unit, :string
      add :division_id, :string
      add :rating_period_start_date, :date
      add :rating_period_end_date, :date

      timestamps(type: :timestamptz)
    end
  end
end

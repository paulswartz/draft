defmodule Draft.Repo.Migrations.SessionUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(
             :bid_sessions,
             [:booking_id, :session_id, :scheduling_unit],
             name: :unique_session_scheduling_index
           )
  end
end

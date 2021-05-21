defmodule Draft.Repo.Migrations.CreateBidRounds do
  use Ecto.Migration

  def change do
    create table(:bid_rounds, primary_key: false) do
      add :process_id, :string
      add :round_id, :string
      add :round_opening_date, :date
      add :round_closing_date, :date
      add :bid_type, :string
      add :rank, :integer
      add :service_context, :string
      add :division_id, :string
      add :division_description, :string
      add :booking_id, :string
      add :rating_period_start_date, :date
      add :rating_period_end_date, :date

      timestamps(type: :timestamptz)
    end

    create unique_index(:bid_rounds, [:process_id, :round_id])

  end
end

defmodule Draft.VacationDistributionRun do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vacation_distribution_runs" do
    field :end_time, :utc_datetime
    field :process_id, :string
    field :round_id, :string
    field :start_time, :utc_datetime
    has_many :vacation_distributions, Draft.VacationDistribution, foreign_key: :run_id

    timestamps()
  end

  @doc false
  def changeset(vacation_distribution_run, attrs) do
    vacation_distribution_run
    |> cast(attrs, [:process_id, :round_id, :start_time, :end_time])
    |> validate_required([:process_id, :round_id, :start_time, :end_time])
  end
end

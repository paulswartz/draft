defmodule Draft.VacationDistribution do
  @moduledoc """
    Represents vacation time that has been distributed by Draft.
  """
  use Ecto.Schema
  alias Draft.FormattingHelpers

  schema "vacation_distributions" do
    field :run_id, :integer
    field :employee_id, :string
    field :interval_type, :string
    field :start_date, :date
    field :end_date, :date
    field :status, :integer, default: 1
    field :rolled_back, :boolean, default: false
    has_one :vacation_distribution_run, Draft.VacationDistributionRun, foreign_key: :id
  end

  @type t :: %__MODULE__{
          run_id: number(),
          employee_id: String.t(),
          interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          status: number(),
          rolled_back: boolean()
        }
  @spec to_csv_row(Draft.VacationDistribution.t()) :: iodata()
  def to_csv_row(distribution) do
    vacation_interval_type = if distribution.interval_type == "week", do: "1", else: "0"
    # For now, assume always quarterly pick
    pick_period = 1

    PipeSeparatedParser.dump_to_iodata([
      [
        "vacation",
        distribution.employee_id,
        vacation_interval_type,
        FormattingHelpers.to_date_string(distribution.start_date),
        FormattingHelpers.to_date_string(distribution.end_date),
        distribution.status,
        pick_period
      ]
    ])
  end
end

defmodule Draft.VacationDistribution do
  @moduledoc """
    Represents vacation time that has been distributed by Draft.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.FormattingHelpers
  alias Draft.Repo

  schema "vacation_distributions" do
    field :run_id, :integer
    field :employee_id, :string
    field :interval_type, :string
    field :start_date, :date
    field :end_date, :date
    field :status, :integer, default: 1
    has_one :vacation_distribution_run, Draft.VacationDistributionRun, foreign_key: :id

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{
          run_id: number(),
          employee_id: String.t(),
          interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          status: number()
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

  @spec insert_all_distributions(number(), [t()]) ::
          {:ok, any()}
          | {:error, any()}
  @doc """
  Insert all given distribution records as part of the given run.
  """
  def insert_all_distributions(run_id, distributions) do
    Repo.transaction(fn ->
      Enum.each(distributions, fn d ->
        Repo.insert!(
          changeset(%__MODULE__{}, Map.put(Draft.Utils.convert_to_map(d), :run_id, run_id))
        )
      end)
    end)
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(vacation_distribution, attrs) do
    vacation_distribution
    |> cast(attrs, [
      :run_id,
      :employee_id,
      :interval_type,
      :start_date,
      :end_date,
      :status
    ])
    |> validate_required([
      :run_id,
      :employee_id,
      :interval_type,
      :start_date,
      :end_date,
      :status
    ])
  end
end

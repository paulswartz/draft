defmodule Draft.VacationDistribution do
  @moduledoc """
    Represents vacation time that has been distributed by Draft.
  """
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Draft.FormattingHelpers
  alias Draft.Repo

  schema "vacation_distributions" do
    field :run_id, :integer
    field :employee_id, :string
    field :interval_type, Draft.IntervalType
    field :start_date, :date
    field :end_date, :date
    field :status, Draft.VacationStatusEnum, default: :assigned
    field :synced_to_hastus, :boolean, default: false
    has_one :vacation_distribution_run, Draft.VacationDistributionRun, foreign_key: :id

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{
          run_id: integer(),
          employee_id: String.t(),
          interval_type: Draft.IntervalType.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          status: Draft.VacationStatusEnum.t(),
          synced_to_hastus: boolean()
        }
  @spec to_csv_row(Draft.VacationDistribution.t()) :: iodata()
  def to_csv_row(distribution) do
    vacation_interval_type = if distribution.interval_type == :week, do: "1", else: "0"
    {:ok, status} = Draft.VacationStatusEnum.dump(distribution.status)
    require Logger
    # For now, assume always quarterly pick
    pick_period = 1

    PipeSeparatedParser.dump_to_iodata([
      [
        "vacation",
        distribution.employee_id,
        vacation_interval_type,
        FormattingHelpers.to_date_string(distribution.start_date),
        FormattingHelpers.to_date_string(distribution.end_date),
        status,
        pick_period
      ]
    ])
  end

  @spec add_distributions_to_run(number(), [t()]) ::
          {:ok, any()}
          | {:error, any()}
  @doc """
  Insert all given distribution records as part of the given run.
  """
  def add_distributions_to_run(run_id, distributions) do
    Repo.transaction(fn ->
      Enum.each(distributions, fn d ->
        Repo.insert!(changeset(%__MODULE__{}, Map.from_struct(Map.put(d, :run_id, run_id))))
      end)
    end)
  end

  @spec count_unsynced_assignments_by_date(integer(), Draft.IntervalType.t()) :: %{
          Date.t() => String.t()
        }
  @doc """
  For the given run id & interval type, count the number of **assigned** distributions that have not
  yet been synced to HASTUS, and therefore are not reflected in the division quotas. This does not account for any cancelled vacations.
  The result is grouped by date, using the start_date for the week interval type.
  Ex: {~D[01-01-2021] => 5, ~D[01-02-2021] => 2 ]} would
  indicate that there are 5 vacations assigned on 1/1/2021 that aren't synced yet to HASTUS, and 2 on 1/2/2021.
  """
  def count_unsynced_assignments_by_date(run_id, interval_type) do
    unsynced_distributions_query =
      from(d in Draft.VacationDistribution,
        where:
          d.interval_type == ^interval_type and d.run_id == ^run_id and d.status == :assigned and
            d.synced_to_hastus == false,
        select: d.start_date
      )

    unsynced_distributions_query
    |> Repo.all()
    |> Enum.frequencies()
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
      :status,
      :synced_to_hastus
    ])
    |> validate_required([
      :run_id,
      :employee_id,
      :interval_type,
      :start_date,
      :end_date,
      :status,
      :synced_to_hastus
    ])
  end
end

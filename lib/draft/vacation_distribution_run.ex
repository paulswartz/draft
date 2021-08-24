defmodule Draft.VacationDistributionRun do
  @moduledoc """
  Represents a distribution attempt for a particular round, and all the associated vacations that are distributed to
  employees in that round.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.Repo

  @type t :: %__MODULE__{
          id: integer(),
          process_id: String.t(),
          round_id: String.t(),
          group_number: integer(),
          start_time: DateTime.t(),
          end_time: DateTime.t() | nil,
          vacation_distributions: [Draft.VacationDistribution.t()]
        }

  @type id :: integer()

  schema "vacation_distribution_runs" do
    field :end_time, :utc_datetime
    field :process_id, :string
    field :round_id, :string
    field :group_number, :integer
    has_many :vacation_distributions, Draft.VacationDistribution, foreign_key: :run_id

    timestamps(type: :utc_datetime, inserted_at: :start_time)
  end

  @spec insert(Draft.BidGroup.t()) :: integer()
  @doc """
  Insert a new distribution run
  """
  def insert(%Draft.BidGroup{
        process_id: process_id,
        round_id: round_id,
        group_number: group_number
      }) do
    Repo.insert!(%__MODULE__{
      process_id: process_id,
      round_id: round_id,
      group_number: group_number
    }).id
  end

  @spec mark_complete(number) :: {:ok, t(), :error, Ecto.Changeset.t()}
  @doc """
  Mark the given distribution run as complete
  """
  def mark_complete(run_id) do
    run_id
    |> mark_complete_changeset(%{end_time: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()

  @spec last_distributed_group(Draft.BidRound.t()) :: integer() | nil
  @doc """
  Get the group number of the last group that was successfully distributed to as part of the given round. Returns nil if no group has been distributed to yet.
  """
  def last_distributed_group(round) do
    Draft.Repo.one(
      from dr in Draft.VacationDistributionRun,
        where:
          dr.round_id == ^round.round_id and dr.process_id == ^round.process_id and
            not is_nil(dr.end_time),
        order_by: [desc: dr.group_number],
        select: dr.group_number,
        limit: 1
    )
  end

  @doc false
  def changeset(vacation_distribution_run, attrs) do
    vacation_distribution_run
    |> cast(attrs, [:process_id, :round_id, :group_number, :start_time, :end_time])
    |> validate_required([:process_id, :round_id, :group_number, :start_time, :end_time])
  end

  defp mark_complete_changeset(run_id, attrs) do
    %__MODULE__{id: run_id}
    |> cast(attrs, [:id, :end_time])
    |> validate_required([:id, :end_time])
  end
end

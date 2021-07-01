defmodule Draft.VacationDistributionRun do
  @moduledoc """
  Represents a distribution attempt for a particular round, and all the associated vacations that are distributed to
  employees in that round.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.Repo

  @type t :: %__MODULE__{
          id: integer(),
          process_id: String.t(),
          round_id: String.t(),
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          vacation_distributions: [Draft.VacationDistribution.t()]
        }

  schema "vacation_distribution_runs" do
    field :end_time, :utc_datetime
    field :process_id, :string
    field :round_id, :string
    has_many :vacation_distributions, Draft.VacationDistribution, foreign_key: :run_id

    timestamps(type: :utc_datetime, inserted_at: :start_time)
  end

  @spec insert(String.t(), String.t()) :: integer()
  @doc """
  Insert a new distribution run
  """
  def insert(process_id, round_id) do
    Repo.insert!(%__MODULE__{process_id: process_id, round_id: round_id}).id
  end

  @spec mark_complete(number) :: {:ok, t(), :error, Ecto.Changeset.t()}
  @doc """
  Mark the given distribution run as complete
  """
  def mark_complete(run_id) do
    Repo.update(changeset(%__MODULE__{}, %{id: run_id, end_time: DateTime.utc_now()}))
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
  def changeset(vacation_distribution_run, attrs) do
    vacation_distribution_run
    |> cast(attrs, [:process_id, :round_id, :start_time, :end_time])
    |> validate_required([:process_id, :round_id, :start_time, :end_time])
  end
end

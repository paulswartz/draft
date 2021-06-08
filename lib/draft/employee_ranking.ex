defmodule Draft.EmployeeRanking do
  @moduledoc """
  EmployeeRanking represents an employee's rank within a particular group for a particular bid round.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.Repo

  @type t :: %__MODULE__{
          process_id: String.t(),
          round_id: String.t(),
          group_number: integer(),
          employee_id: String.t(),
          name: String.t(),
          rank: integer(),
          job_class: String.t()
        }

  @primary_key false
  schema "employee_rankings" do
    field :employee_id, :string, primary_key: true
    field :group_number, :integer
    field :job_class, :string
    field :name, :string
    field :process_id, :string, primary_key: true
    field :rank, :integer
    field :round_id, :string, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      process_id,
      round_id,
      group_number,
      rank,
      employee_id,
      name,
      job_class
    ] = row

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      group_number: String.to_integer(group_number),
      rank: String.to_integer(rank),
      employee_id: employee_id,
      name: name,
      job_class: job_class
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_ranking, attrs \\ %{}) do
    employee_ranking
    |> cast(attrs, [:process_id, :round_id, :group_number, :rank, :employee_id, :name, :job_class])
    |> validate_required([
      :process_id,
      :round_id,
      :group_number,
      :rank,
      :employee_id,
      :name,
      :job_class
    ])
  end

  @spec get_latest_ranking(String.t()) :: EmployeeRanking.t() | nil
  def get_latest_ranking(badge_number) do
    Repo.one(from e in Draft.EmployeeRanking, join: g in Draft.BidGroup, on: e.group_number == g.group_number and g.process_id == e.process_id and g.round_id == e.round_id, where: e.employee_id == ^badge_number, order_by: [desc: g.cutoff_datetime], select: %{cutoff_time: g.cutoff_datetime, employee_id: e.employee_id, rank: e.rank}, limit: 1)
  end
end

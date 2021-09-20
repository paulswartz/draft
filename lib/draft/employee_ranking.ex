defmodule Draft.EmployeeRanking do
  @moduledoc """
  EmployeeRanking represents an employee's rank within a particular group for a particular bid round.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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

  @spec exists?(%{round_id: String.t(), process_id: String.t(), employee_id: String.t()}) ::
          boolean()
  @doc """
  Is this employee a part of the given round?
  """
  def exists?(%{round_id: round_id, process_id: process_id, employee_id: employee_id}) do
    Draft.Repo.exists?(
      from e in __MODULE__,
        where:
          e.round_id == ^round_id and
            e.process_id == ^process_id and
            e.employee_id == ^employee_id
    )
  end

  @spec valid_employee_id?(String.t()) :: boolean()
  @doc """
  Does there exist an employee with the given badge number?
  """
  def valid_employee_id?(employee_id) do
    Draft.Repo.exists?(
      from e in __MODULE__,
        where: e.employee_id == ^employee_id
    )
  end

  @spec all_remaining_employees(
          %{:round_id => String.t(), :process_id => String.t(), optional(atom()) => any()},
          :asc | :desc
        ) ::
          [t()]
  @doc """
  All employees that are part of the given round and in a later group than the one given.
  """
  def all_remaining_employees(%{round_id: round_id, process_id: process_id}, order) do
    last_distributed_group_number =
      Draft.VacationDistributionRun.last_distributed_group(round_id, process_id) || 0

    Draft.Repo.all(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number > ^last_distributed_group_number,
        order_by: [{^order, e.group_number}, {^order, e.rank}]
    )
  end

  @spec all_operators_in_group(Draft.BidGroup.t()) :: [t()]
  @doc """
  Get all employees that are part of the given group
  with the most senior operator returned first.
  """
  def all_operators_in_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
    Draft.Repo.all(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number == ^group_number,
        order_by: [asc: [e.rank]]
    )
  end

  @spec operator_by_rank(%{
          round_id: String.t(),
          process_id: String.t(),
          group_number: pos_integer(),
          rank: pos_integer()
        }) :: t()
  @doc """
  Get the operator that has the given rank in the given group.
  """
  def operator_by_rank(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number,
        rank: rank
      }) do
    Draft.Repo.one!(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number == ^group_number and e.rank == ^rank
    )
  end

  @spec all_operators_in_and_after_group(Draft.BidGroup.t()) :: [t()]
  @doc """
  Get all employees that are part of the given group & all subsequent groups,
  with the most senior operator returned first.
  """
  def all_operators_in_and_after_group(%{
        round_id: round_id,
        process_id: process_id,
        group_number: group_number
      }) do
    Draft.Repo.all(
      from e in Draft.EmployeeRanking,
        where:
          e.round_id == ^round_id and e.process_id == ^process_id and
            e.group_number >= ^group_number,
        order_by: [asc: [e.group_number, e.rank]]
    )
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
end

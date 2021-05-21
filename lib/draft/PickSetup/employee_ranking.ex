defmodule Draft.PickSetup.EmployeeRanking do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    process_id: String.t(),
    round_id: String.t(),
    group_number: integer(),
    employee_id: String.t(),
    name: String.t(),
    rank: integer(),
    job_class: String.t()
  }

  schema "employee_rankings" do
    field :employee_id, :string
    field :group_number, :integer
    field :job_class, :string
    field :name, :string
    field :process_id, :string
    field :rank, :integer
    field :round_id, :string

    timestamps(type: :utc_datetime)
  end

  def parse(row) do
    [
      process_id,
      round_id,
      group_number,
      rank,
      employee_id,
      name,
      job_class
    ] = row
    timestamp = DateTime.truncate(DateTime.utc_now(), :second)

    %{
      process_id: process_id,
      round_id: round_id,
      group_number: String.to_integer(group_number),
      rank: String.to_integer(rank),
      employee_id: employee_id,
      name: name,
      job_class: job_class,
      inserted_at: timestamp,
      updated_at: timestamp
    }
  end

  @doc false
  def changeset(employee_ranking, attrs) do
    employee_ranking
    |> cast(attrs, [:process_id, :round_id, :group_number, :rank, :employee_id, :name, :job_class])
    |> validate_required([:process_id, :round_id, :group_number, :rank, :employee_id, :name, :job_class])
  end
end

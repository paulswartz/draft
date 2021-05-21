defmodule Draft.PickSetup.BidGroup do
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.PickSetup.ParsingHelpers

  @type t :: %__MODULE__{
    process_id: String.t(),
    round_id: String.t(),
    group_number: integer(),
    cutoff_datetime: Datetime.t()
  }

  schema "bid_groups" do
    field :cutoff_datetime, :utc_datetime
    field :group_number, :integer
    field :process_id, :string
    field :round_id, :string

    timestamps(type: :utc_datetime)
  end

  def parse(row) do
    [
      process_id,
      round_id,
      group_number,
      cutoff_date,
      cutoff_time
    ] = row
    timestamp = DateTime.truncate(DateTime.utc_now(), :second)
    struct = %{
      process_id: process_id,
      round_id: round_id,
      group_number: String.to_integer(group_number),
      cutoff_datetime: ParsingHelpers.to_datetime(cutoff_date, cutoff_time),
      inserted_at: timestamp,
      updated_at: timestamp
    }
    end

  @doc false
  def changeset(bid_group, attrs) do
    bid_group
    |> cast(attrs, [:process_id, :round_id, :group_number, :cutoff_datetime])
    |> validate_required([:process_id, :round_id, :group_number, :cutoff_datetime])
  end
end

defmodule Draft.BidGroup do
  @moduledoc """
  A Bid Group defines a collection of employees that must select their preferences by a specified cutoff time.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.PickDataSetup.ParsingHelpers

  @type t :: %__MODULE__{
          process_id: String.t(),
          round_id: String.t(),
          group_number: integer(),
          cutoff_datetime: DateTime.t()
        }

  @primary_key false
  schema "bid_groups" do
    field :cutoff_datetime, :utc_datetime
    field :group_number, :integer
    field :process_id, :string
    field :round_id, :string

    timestamps(type: :utc_datetime)
  end

  @spec from_parts([String.t()]) :: map()
  def from_parts(row) do
    [
      process_id,
      round_id,
      group_number,
      cutoff_date,
      cutoff_time
    ] = row

    timestamp = DateTime.truncate(DateTime.utc_now(), :second)

    %{
      process_id: process_id,
      round_id: round_id,
      group_number: String.to_integer(group_number),
      cutoff_datetime: ParsingHelpers.to_utc_datetime(cutoff_date, cutoff_time),
      inserted_at: timestamp,
      updated_at: timestamp
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bid_group, attrs) do
    bid_group
    |> cast(attrs, [:process_id, :round_id, :group_number, :cutoff_datetime])
    |> validate_required([:process_id, :round_id, :group_number, :cutoff_datetime])
  end
end

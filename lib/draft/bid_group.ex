defmodule Draft.BidGroup do
  @moduledoc """
  A Bid Group defines a collection of employees that must select their preferences by a specified cutoff time.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          process_id: String.t(),
          round_id: String.t(),
          group_number: integer(),
          cutoff_datetime: DateTime.t()
        }

  @primary_key false
  schema "bid_groups" do
    field :cutoff_datetime, :utc_datetime
    field :group_number, :integer, primary_key: true
    field :process_id, :string, primary_key: true
    field :round_id, :string, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      process_id,
      round_id,
      group_number,
      cutoff_date,
      cutoff_time
    ] = row

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      group_number: String.to_integer(group_number),
      cutoff_datetime: ParsingHelpers.hastus_format_to_utc_datetime(cutoff_date, cutoff_time)
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bid_group, attrs \\ %{}) do
    bid_group
    |> cast(attrs, [:process_id, :round_id, :group_number, :cutoff_datetime])
    |> validate_required([:process_id, :round_id, :group_number, :cutoff_datetime])
  end
end
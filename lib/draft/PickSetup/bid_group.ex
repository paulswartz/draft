defmodule Draft.PickSetup.BidGroup do
  use Ecto.Schema
  import Ecto.Changeset

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

    timestamps()
  end

  @doc false
  def changeset(bid_group, attrs) do
    bid_group
    |> cast(attrs, [:process_id, :round_id, :group_number, :cutoff_datetime])
    |> validate_required([:process_id, :round_id, :group_number, :cutoff_datetime])
  end
end

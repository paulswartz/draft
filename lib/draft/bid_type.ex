defmodule Draft.BidType do
  @moduledoc """
  Represent bid types
  """
  use EctoEnum, vacation: "vacation", work: "work"

  @spec from_hastus(String.t()) :: t()
  @doc """
  Return the appropriate bid type from the HASTUS formatted value.
  """
  def from_hastus(bid_type) do
    {:ok, type_enum} =
      bid_type
      |> String.downcase()
      |> Draft.BidType.load()

    type_enum
  end
end

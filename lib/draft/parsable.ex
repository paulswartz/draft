defmodule Draft.Parsable do
  @moduledoc """
  Defines contract for parsable modules.
  """
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking

  @callback from_parts([String.t()]) :: t()

  @type t :: BidRound.t() | EmployeeRanking.t() | BidGroup.t()

  @spec from_parts([String.t()]) :: t()
  @doc """
  Returns a struct created from the given ordered list of strings. The type of struct returned is determined
  by the first string in the list.
  """
  def from_parts([record_type | rest]) do
    record_struct(record_type).from_parts(rest)
  end

  defp record_struct("R"), do: BidRound
  defp record_struct("E"), do: EmployeeRanking
  defp record_struct("G"), do: BidGroup
end

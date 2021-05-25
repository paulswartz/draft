defmodule Draft.Parsable do
  @moduledoc """
  Defines contract for parsable modules.
  """
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking

  @callback from_parts([String.t()]) :: t()

  @type t :: struct()

  @spec from_parts(module(), [String.t()]) :: struct()
  @doc """
  Returns a struct for the given module type created from the given ordered list of strings.
  """
  def from_parts(record_module, parts) do
    record_module.from_parts(parts)
  end

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

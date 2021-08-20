defmodule Draft.Parsable do
  @moduledoc """
  Defines contract for parsable modules.
  """
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.BidSession
  alias Draft.EmployeeRanking
  alias Draft.RosterAvailability
  alias Draft.RosterSet

  @callback from_parts([String.t()]) :: t()

  @type t :: struct()

  @spec from_parts(module(), [String.t()]) :: struct()
  @doc """
  Returns a struct for the given module type created from the given ordered list of strings.
  """
  def from_parts(BidRound, [record_type | parts]) do
    case record_type do
      "R" -> BidRound.from_parts(parts)
      "E" -> EmployeeRanking.from_parts(parts)
      "G" -> BidGroup.from_parts(parts)
    end
  end

  def from_parts(BidSession, [record_type | parts]) do
    case record_type do
      "S" -> BidSession.from_parts(parts)
      "R" -> RosterSet.from_parts(parts)
      "A" -> RosterAvailability.from_parts(parts)
    end
  end

  def from_parts(record_module, parts) do
    record_module.from_parts(parts)
  end
end

defmodule Draft.PickSetup do
  @moduledoc """
  The Pick Setup context.
  """

  import Ecto.Query, warn: false
  alias Draft.Repo
  alias Draft.PickSetup.ParsingHelpers
  alias Draft.PickSetup.BidRound
  alias Draft.PickSetup.BidGroup
  alias Draft.PickSetup.EmployeeRanking


  def parse_bid_rounds() do
    grouped_records =
      "../../bid-round-group-emp.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode(separator: ?|, validate_row_length: false)
      |> Enum.map(fn {:ok, [record_type | record_data]} -> {record_type, record_data} end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    grouped_records["R"]
    |> insert_from_extract()
    grouped_records["G"]
    |> insert_groups_from_extract()

    grouped_records["E"]
    |> insert_employee_ranks_from_extract()

  end

  def insert_from_extract(rounds) do
    parsed_rounds = rounds
    |> Enum.map(&BidRound.parse(&1))

    require Logger
    Logger.error(inspect(parsed_rounds))

    Repo.insert_all(BidRound, parsed_rounds, on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:process_id, :round_id])

  end

  def insert_groups_from_extract(rounds) do
    parsed_rounds = rounds
    |> Enum.map(&BidGroup.parse(&1))

    require Logger
    Logger.error(inspect(parsed_rounds))

    Repo.insert_all(BidGroup, parsed_rounds, on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:process_id, :round_id, :group_number])

  end

  def insert_employee_ranks_from_extract(rounds) do
    parsed_rounds = rounds
    |> Enum.map(&EmployeeRanking.parse(&1))

    require Logger
    Logger.error(inspect(parsed_rounds))

    Repo.insert_all(EmployeeRanking, parsed_rounds, on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:process_id, :round_id, :employee_id])

  end



  defp parse_row(row_contents) do
    {record_type, all_record_data} = row_contents

    case record_type do
      _ -> true
    end
  end
end

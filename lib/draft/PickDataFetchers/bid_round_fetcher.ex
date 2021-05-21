defmodule Draft.PickDataFetchers.BidRoundFetcher do
  @moduledoc """
  The Pick Setup context.
  """

  import Ecto.Query, warn: false
  alias Draft.Repo
  alias Draft.PickDataFetchers.ParsingHelpers
  alias Draft.BidRound
  alias Draft.BidGroup
  alias Draft.EmployeeRanking


  def parse_and_save(filename) do
    record_processors = %{"R" => %{parser: &BidRound.parse(&1), saver: &insert_all_rounds(&1)},
    "G" => %{parser: &BidGroup.parse(&1), saver: &insert_groups_from_extract(&1)},
    "E" => %{parser: &EmployeeRanking.parse(&1), saver: &insert_employee_ranks_from_extract(&1)}}


    grouped_records = filename
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?|, validate_row_length: false)
    |> Enum.map(fn {:ok, [record_type | record_data]} -> {record_type, record_data} end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{}, fn {record_type, record_data} -> {record_type, Enum.map(record_data, record_processors[record_type].parser())} end)


    require Logger
   # Logger.error(inspect(grouped_records))

    Enum.map(["R", "G", "E"], fn record_type -> record_processors[record_type].saver.(grouped_records[record_type]) end)



  end


  def insert_all_rounds(rounds) do
    require Logger
    Logger.error("ROUNDS")
    Logger.error(rounds)

    Repo.insert_all(BidRound, rounds, on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: [:process_id, :round_id])

  end

  def insert_groups_from_extract(rounds) do

    Repo.insert_all(BidGroup, rounds, on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: [:process_id, :round_id, :group_number])

  end

  def insert_employee_ranks_from_extract(rounds) do
    Repo.insert_all(EmployeeRanking, rounds, on_conflict: {:replace_all_except, [:id, :inserted_at]}, conflict_target: [:process_id, :round_id, :employee_id])

  end


end

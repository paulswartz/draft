defmodule Draft.PickDataSetup.BidRoundSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.Repo
  alias NimbleCSV.RFC4180, as: CSV

  NimbleCSV.define(PipeSeparatedParser, separator: "\|")

  @spec update_bid_round_data(String.t()) :: [{integer(), nil | [term()]}]
  def update_bid_round_data(filename) do
    records_by_type =
      filename
      |> parse_data()
      |> group_by_record_type()

    Enum.map(["R", "G", "E"], fn record_type ->
      batch_upsert_data(record_type, records_by_type[record_type])
    end)
  end

  defp parse_data(filename) do
    filename
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> PipeSeparatedParser.parse_stream(skip_headers: false)
    |> Enum.map(fn [record_type | record_data] -> {record_type, record_data} end)
  end

  defp group_by_record_type(all_records) do
    all_records
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{}, fn {record_type, record_data} ->
      {record_type, Enum.map(record_data, &from_parts(record_type, &1))}
    end)
  end

  defp batch_upsert_data("R", records) do
    Repo.insert_all(BidRound, records,
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:process_id, :round_id]
    )
  end

  defp batch_upsert_data("G", records) do
    Repo.insert_all(BidGroup, records,
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:process_id, :round_id, :group_number]
    )
  end

  defp batch_upsert_data("E", records) do
    Repo.insert_all(EmployeeRanking, records,
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:process_id, :round_id, :employee_id]
    )
  end

  defp from_parts("R", row) do
    BidRound.from_parts(row)
  end

  defp from_parts("E", row) do
    EmployeeRanking.from_parts(row)
  end

  defp from_parts("G", row) do
    BidGroup.from_parts(row)
  end
end

defmodule Draft.PickDataSetup.BidRoundSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.Repo

  NimbleCSV.define(PipeSeparatedParser, separator: "\|")

  @spec update_bid_round_data(String.t()) :: [{integer(), nil | [term()]}]
  def update_bid_round_data(filename) do
    records_by_type =
      filename
      |> parse_data()
      |> group_by_record_type()

      delete_rounds(records_by_type["R"])
    Enum.map(["R", "G", "E"], fn record_type ->
      insert_all_records(record_type, records_by_type[record_type])
    end)
  end

  defp delete_rounds(rounds) do
    rounds
    |> Enum.each(fn round -> Repo.delete_all(from(
      r in BidRound,
      where:
        r.process_id == ^round.process_id and r.round_id == ^round.round_id
    )) end)
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

  defp insert_all_records("R", records) do
    records |>
    Enum.each(fn record -> Repo.insert(BidRound.changeset(%BidRound{}, record)) end)
  end

  defp insert_all_records("G", records) do
    records |>
    Enum.each( fn record -> Repo.insert(BidGroup.changeset(%BidGroup{}, record)) end)
  end

  defp insert_all_records("E", records) do
    records |>
    Enum.each(fn record -> Repo.insert(EmployeeRanking.changeset(%EmployeeRanking{}, record)) end)
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

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
  @doc """
  Reads bid round, group, and employee data from the given file and stores it in the database.
  If there was already data stored for any round present in the file, that data will be removed & re-inserted.
  """
  def update_bid_round_data(filename) do
    records_by_type =
      filename
      |> parse_data()
      |> group_by_record_type()

    Repo.transaction(fn ->
      delete_rounds(records_by_type[BidRound])

      Enum.map([BidRound, BidGroup, EmployeeRanking], fn record_type ->
        insert_all_records(records_by_type[record_type])
      end)
    end)
  end

  defp delete_rounds(rounds) do
    Enum.each(rounds, fn round ->
      Repo.delete_all(
        from(
          r in BidRound,
          where: r.process_id == ^round.process_id and r.round_id == ^round.round_id
        )
      )
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
    record_types = %{"R" => BidRound, "E" => EmployeeRanking, "G" => BidGroup}

    all_records
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{}, fn {record_type_id, record_data} ->
      {record_types[record_type_id],
       Enum.map(record_data, fn data -> record_types[record_type_id].from_parts(data) end)}
    end)
  end

  defp insert_all_records(records) do
    Enum.each(records, fn record -> Repo.insert(record) end)
  end
end

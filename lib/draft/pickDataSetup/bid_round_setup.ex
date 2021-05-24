defmodule Draft.PickDataSetup.BidRoundSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.Repo

  @spec update_bid_round_data(String.t()) :: [{integer(), nil | [term()]}]
  def update_bid_round_data(filename) do
    records_by_type =
      filename
      |> parse_data()
      |> group_by_record_type()

    Enum.map(["R", "G", "E"], fn record_type ->
      batch_upsert_data({record_type, records_by_type[record_type]})
    end)
  end

  defp parse_data(filename) do
    filename
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(separator: ?|, validate_row_length: false)
    |> Enum.map(fn {:ok, [record_type | record_data]} -> {record_type, record_data} end)
  end

  defp group_by_record_type(all_records) do
    record_processors = %{
      "R" => %{from_parts_fn: &BidRound.from_parts(&1)},
      "G" => %{from_parts_fn: &BidGroup.from_parts(&1)},
      "E" => %{
        from_parts_fn: &EmployeeRanking.from_parts(&1)
      }
    }

    all_records
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{}, fn {record_type, record_data} ->
      {record_type, Enum.map(record_data, record_processors[record_type].from_parts_fn())}
    end)
  end

  defp batch_upsert_data({record_type, records}) do
    case record_type do
      "R" ->
        Repo.insert_all(BidRound, records,
          on_conflict: {:replace_all_except, [:id, :inserted_at]},
          conflict_target: [:process_id, :round_id]
        )

      "G" ->
        Repo.insert_all(BidGroup, records,
          on_conflict: {:replace_all_except, [:id, :inserted_at]},
          conflict_target: [:process_id, :round_id, :group_number]
        )

      "E" ->
        Repo.insert_all(EmployeeRanking, records,
          on_conflict: {:replace_all_except, [:id, :inserted_at]},
          conflict_target: [:process_id, :round_id, :employee_id]
        )
    end
  end
end

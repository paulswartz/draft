defmodule Draft.PickSetup do
  @moduledoc """
  The Pick Setup context.
  """

  import Ecto.Query, warn: false
  alias Draft.Repo
  import CSV

  alias Draft.PickSetup.BidRound

  def parse_bid_rounds(filename) do
    first_rows =
      "../../bid-round-group-emp.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode(separator: ?|, validate_row_length: false)
      |> Stream.map(&parse_row(&1))
      |> Enum.take(4)

    require Logger
    Logger.error(inspect(first_rows))
  end

  defp parse_row(row_contents) do
    headers = %{"R" => [
      "process_id",
      "round_id",
      "round_opening_date",
      "round_closing_date",
      "bid_type",
      "rank",
      "service_context",
      "division_id",
      "division_description",
      "booking_id",
      "rating_period_start_date",
      "rating_period_end_date"
    ], "G" => [
      "process_id",
      "round_id",
      "group_number",
      "cutoff_date",
      "cutoff_time"
    ], "E" => [
      "process_id",
      "round_id",
      "group_number",
      "rank",
      "employee_id",
      "name",
      "job_class"
    ],
  }

  {:ok, [record_type | row]} = row_contents
      headers[record_type]
      |> Enum.zip(row)
      |> Enum.into(%{})
  end
end

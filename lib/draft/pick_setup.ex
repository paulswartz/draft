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
    {:ok, [record_type | row]} = row_contents

    case record_type do
      "R" ->
        [
          process_id,
          round_id,
          round_opening_date,
          round_closing_date,
          bid_type,
          rank,
          service_context,
          division_id,
          division_description,
          booking_id,
          rating_period_start_date,
          rating_period_end_date
        ] = row

        struct = %{
          process_id: process_id,
          round_id: round_id,
          round_opening_date: ParsingHelpers.to_date(round_opening_date),
          round_closing_date: ParsingHelpers.to_date(round_closing_date),
          bid_type: bid_type,
          rank: String.to_integer(rank),
          service_context: service_context,
          division_id: division_id,
          division_description: division_description,
          booking_id: booking_id,
          rating_period_start_date: ParsingHelpers.to_date(rating_period_start_date),
          rating_period_end_date: ParsingHelpers.to_date(rating_period_end_date)
        }

        %BidRound{}
        |> BidRound.changeset(struct)
        |> Repo.insert()

        struct

      "G" ->
        [
          process_id,
          round_id,
          group_number,
          cutoff_date,
          cutoff_time
        ] = row

        struct = %{
          process_id: process_id,
          round_id: round_id,
          group_number: String.to_integer(group_number),
          cutoff_datetime: ParsingHelpers.to_datetime(cutoff_date, cutoff_time)
        }
        %BidGroup{}
        |> BidGroup.changeset(struct)
        |> Repo.insert()

        struct

      "E" ->
        [
          process_id,
          round_id,
          group_number,
          rank,
          employee_id,
          name,
          job_class
        ] = row

        struct = %{
          process_id: process_id,
          round_id: round_id,
          group_number: String.to_integer(group_number),
          rank: String.to_integer(rank),
          employee_id: employee_id,
          name: name,
          job_class: job_class
        }
        %EmployeeRanking{}
        |> EmployeeRanking.changeset(struct)
        |> Repo.insert()

        struct
    end
  end
end

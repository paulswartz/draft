defmodule Draft.BidProcessSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.BidSession
  alias Draft.EmployeeRanking
  alias Draft.Parsable
  alias Draft.ParsingHelpers
  alias Draft.Repo
  alias Draft.VacationDistributionScheduler

  @default_files %{
    Draft.BidRound => "../../data/latest/BW_Project_Draft-Bid_Round-Group-Emp.csv",
    Draft.BidSession => "../../data/latest/BW_Project_Draft-Bid_Session-Roster_Set.csv",
    Draft.RosterDay => "../../data/latest/BW_Project_Draft-Roster_day.csv"
  }

  @spec update_bid_process(%{module() => ParsingHelpers.filename()}) :: [
          {integer(), nil | [term()]}
        ]
  @doc """
  Reads all data defining the bid process & store the data in the database.

  - `round_file`: Location of the pipe separated file storing bid round / group / employees
  - `session_file`: Location of the pipe separated file storing session / roster set / available
  roster data.

  All existing data associated with any round in the `round_file` is deleted, and new records
  inserted based on the data present in the two given files.
  """
  def update_bid_process(bid_process_files \\ @default_files) do
    Repo.transaction(fn ->
      update_rounds(Map.fetch!(bid_process_files, Draft.BidRound))
      update_sessions(Map.fetch!(bid_process_files, Draft.BidSession))
      update_roster_days(Map.fetch!(bid_process_files, Draft.RosterDay))
    end)
  end

  defp update_rounds(round_file) do
    record_parts = ParsingHelpers.parse_pipe_separated_file(round_file)
    records_by_type = group_by_record_type(BidRound, record_parts)

    Repo.transaction(fn ->
      delete_rounds(records_by_type[BidRound])

      Enum.each(
        [
          BidRound,
          BidGroup,
          EmployeeRanking
        ],
        &insert_all_records(records_by_type[&1])
      )

      VacationDistributionScheduler.reset_upcoming_distribution_jobs(
        records_by_type[BidRound],
        records_by_type[BidGroup]
      )
    end)
  end

  defp update_sessions(session_file) do
    record_parts = ParsingHelpers.parse_pipe_separated_file(session_file)
    records_by_type = group_by_record_type(BidSession, record_parts)

    Repo.transaction(fn ->
      Enum.each(
        [
          Draft.BidSession,
          Draft.RosterSet,
          Draft.RosterAvailability
        ],
        &insert_all_records(records_by_type[&1])
      )
    end)
  end

  defp update_roster_days(roster_day_file) do
    records =
      roster_day_file
      |> ParsingHelpers.parse_pipe_separated_file()
      |> Enum.map(&Parsable.from_parts(Draft.RosterDay, &1))

    Repo.transaction(fn ->
      records
      |> MapSet.new(&{&1.booking_id, &1.roster_set_internal_id})
      |> Enum.each(fn {booking_id, roster_set_internal_id} ->
        Repo.delete_all(
          from r in Draft.RosterDay,
            where:
              r.booking_id == ^booking_id and r.roster_set_internal_id == ^roster_set_internal_id
        )
      end)

      insert_all_records(records)
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

  @spec group_by_record_type(module(), Enumerable.t()) :: %{
          module() => [Parsable.t()]
        }
  defp group_by_record_type(root_record, records) do
    records
    |> Enum.map(&Parsable.from_parts(root_record, &1))
    |> Enum.group_by(& &1.__struct__)
  end

  defp insert_all_records(records) do
    Enum.each(records, &Repo.insert(&1))
  end
end

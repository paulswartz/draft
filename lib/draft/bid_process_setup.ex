defmodule Draft.BidProcessSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.Parsable
  alias Draft.ParsingHelpers
  alias Draft.Repo
  alias Draft.VacationDistributionScheduler

  @spec update_bid_process({String.t(), String.t()}) :: [{integer(), nil | [term()]}]
  @doc """
  Reads all data defining the bid process & store the data in the database.

  - `round_file`: Location of the pipe separated file storing bid round / group / employees
  - `session_file`: Location of the pipe separated file storing session / roster set / available
  roster data.

  All existing data associated with any round in the `round_file` is deleted, and new records
  inserted based on the data present in the two given files.
  """
  def update_bid_process(
        {round_file, session_file} \\ {"../../data/latest/BW_Project_Draft-Bid_Round-Group-Emp.csv",
         "data/latest/BW_Project_Draft-Bid_Session-Roster_Set.csv"}
      ) do
    parsed_files =
      Stream.flat_map([round_file, session_file], &ParsingHelpers.parse_pipe_separated_file(&1))

    records_by_type = group_by_record_type(parsed_files)

    Repo.transaction(fn ->
      delete_rounds(records_by_type[BidRound])

      Enum.each([BidRound, BidGroup, EmployeeRanking], fn record_type ->
        insert_all_records(records_by_type[record_type])
      end)

      VacationDistributionScheduler.reset_upcoming_distribution_jobs(
        records_by_type[BidRound],
        records_by_type[BidGroup]
      )
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

  @spec group_by_record_type(Enumerable.t()) :: %{module() => [Parsable.t()]}
  defp group_by_record_type(all_records) do
    all_records
    |> Enum.map(&Parsable.from_parts(&1))
    |> Enum.group_by(& &1.__struct__)
  end

  defp insert_all_records(records) do
    Enum.each(records, &Repo.insert(&1))
  end
end

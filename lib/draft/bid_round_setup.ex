defmodule Draft.BidRoundSetup do
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

  @spec update_bid_round_data(String.t()) :: [{integer(), nil | [term()]}]
  @doc """
  Reads bid round, group, and employee data from the given file and stores it in the database.
  If there was already data stored for any round present in the file, that data will be removed & re-inserted.
  """
  def update_bid_round_data(filename) do
    records_by_type =
      filename
      |> ParsingHelpers.parse_pipe_separated_file()
      |> group_by_record_type()

    Repo.transaction(fn ->
      delete_rounds(records_by_type[BidRound])

      Enum.each([BidRound, BidGroup, EmployeeRanking], fn record_type ->
        Repo.insert_all(record_type, records_by_type[record_type])
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
end

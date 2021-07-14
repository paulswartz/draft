defmodule Draft.VacationDistributionScheduler do
  @moduledoc """
  Support scheduling vacation distribution jobs
  """

  import Ecto.Query
  alias Draft.{BidGroup, BidRound, Repo}

  @spec reset_upcoming_distribution_jobs([BidRound.t()], [BidGroup.t()]) :: :ok
  @doc """
  Cancel any upcoming scheduled distribution jobs for the given rounds
  and insert new jobs for every group given.
  """
  def reset_upcoming_distribution_jobs(rounds, groups) do
    Repo.transaction(fn ->
      cancel_upcoming_distributions(rounds)
      schedule_distributions(groups)
    end)
  end

  @spec cancel_upcoming_distributions([BidRound.t()]) :: :ok
  defp cancel_upcoming_distributions(rounds) do
    rounds
    |> Enum.flat_map(fn round ->
      Repo.all(
        from j in Oban.Job,
          where:
            j.queue == "vacation_distribution" and
              fragment("?->'round_id' = ?", j.args, ^round.round_id) and
              fragment("?->'process_id' = ?", j.args, ^round.process_id) and
              j.scheduled_at >= ^DateTime.utc_now()
      )
    end)
    |> Enum.each(fn j -> Oban.cancel_job(j.id) end)
  end

  @spec schedule_distributions([BidGroup.t()]) :: :ok
  defp schedule_distributions(groups) do
    Enum.each(groups, fn %{cutoff_datetime: cutoff} = group ->
      group
      |> Map.take([:process_id, :round_id, :group_number])
      |> Draft.VacationDistributionWorker.new(scheduled_at: cutoff)
      |> Draft.Repo.insert()
    end)
  end
end

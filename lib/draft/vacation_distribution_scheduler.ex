defmodule Draft.VacationDistributionScheduler do
  @moduledoc """
  Support scheduling vacation distribution jobs
  """

  import Ecto.Query
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.Repo

  @doc """
  Cancel all upcoming distributions associated with the given rounds
  """
  @spec cancel_upcoming_distributions([BidRound]) :: :ok
  def cancel_upcoming_distributions(rounds) do
    rounds
    |> Enum.flat_map(fn round ->
      Repo.all(
        from j in Oban.Job,
          where:
            j.queue == "vacation_distribution" and
              fragment("?->>'round_id' = ?", j.args, ^round.round_id) and
              fragment("?->>'process_id' = ?", j.args, ^round.process_id) and
              j.scheduled_at >= ^DateTime.utc_now()
      )
    end)
    |> Enum.each(fn j -> Oban.cancel_job(j.id) end)
  end

  @doc """
  Schedule all upcoming distributions associated with the given rounds
  """
  @spec schedule_distributions([BidGroup]) :: :ok
  def schedule_distributions(groups) do
    Enum.each(groups, fn g ->
      Draft.Repo.insert(
        Draft.VacationDistributionWorker.new(
          Map.take(g, [:process_id, :round_id, :group_number]),
          scheduled_at: Map.get(g, :cutoff_datetime)
        )
      )
    end)
  end
end

defmodule Draft.VacationDistributionWorker do
  @moduledoc """
  Process scheduled vacation distribution jobs.
  """

  use Oban.Worker, queue: :vacation_distribution, max_attempts: 1
  import Ecto.Query
  alias Draft.BasicVacationDistributionRunner

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    group =
      args
      |> Map.take(["process_id", "round_id", "group_number"])
      |> Map.new(fn {key, val} -> {String.to_existing_atom(key), val} end)

    bid_type =
      Draft.Repo.one(
        from r in Draft.BidRound,
          where:
            r.round_id == ^group.round_id and
              r.process_id == ^group.process_id,
          select: r.bid_type
      )

    process_group(group, bid_type)
  end

  @spec process_group(
          %{round_id: String.t(), process_id: String.t(), group_number: integer()},
          Draft.BidType.t() | nil
        ) :: {:ok, [Draft.VacationDistribution.t()]} | {:error, any()}
  defp process_group(group, bid_type)

  defp process_group(group, :vacation) do
    case Draft.BidSession.vacation_interval(group) do
      nil ->
        {:error, "Vacation interval not defined on sesson"}

      vacation_interval ->
        BasicVacationDistributionRunner.distribute_vacation_to_group(group, vacation_interval)
    end
  end

  defp process_group(_group, nil) do
    {:error, "No bid round found"}
  end
end

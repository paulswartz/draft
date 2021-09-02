defmodule Draft.VacationDistributionWorker do
  @moduledoc """
  Process scheduled vacation distribution jobs.
  """

  use Oban.Worker, queue: :vacation_distribution, max_attempts: 1
  import Ecto.Query
  alias Draft.BasicVacationDistributionRunner
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    group =
      args
      |> Map.take(["process_id", "round_id", "group_number"])
      |> Map.new(fn {key, val} -> {String.to_existing_atom(key), val} end)

    bid_type =
      Draft.Repo.one(
        from r in Draft.BidRound,
          where: r.round_id == ^group.round_id and r.process_id == ^group.process_id,
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
    with {:ok, distributions} <-
           BasicVacationDistributionRunner.distribute_vacation_to_group(group),
         :ok <- export_distributions(group, distributions) do
      {:ok, distributions}
    else
      {:error, e} ->
        _ignored =
          Logger.error(
            "unable to distribute vacation group=#{inspect(group)} error=#{inspect(e)}"
          )

        {:error, e}
    end
  end

  defp process_group(_group, nil) do
    {:error, "No bid round found"}
  end

  @spec export_distributions(
          %{round_id: String.t(), process_id: String.t(), group_number: integer()},
          [Draft.VacationDistribution.t()]
        ) :: :ok | {:error, any()}
  def export_distributions(group, distributions) do
    now = DateTime.utc_now()

    filename =
      "#{DateTime.to_iso8601(now)}_vacation_distribution_#{group.process_id}_#{group.round_id}_#{
        group.group_number
      }.psv"

    iodata = Enum.map(distributions, &Draft.VacationDistribution.to_csv_row/1)

    Draft.Exporter.export(filename, iodata)
  end
end

defmodule Draft.VacationDistributionWorker do
  @moduledoc """
  Process scheduled vacation distribution jobs.
  """

  use Oban.Worker, queue: :vacation_distribution, max_attempts: 1
  alias Draft.BasicVacationDistributionRunner

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    args
    |> Map.take(["process_id", "round_id", "group_number"])
    |> Map.new(fn {key, val} -> {String.to_existing_atom(key), val} end)
    |> BasicVacationDistributionRunner.distribute_vacation_to_group()
  end
end

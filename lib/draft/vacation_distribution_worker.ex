defmodule Draft.VacationDistributionWorker do
  @moduledoc """
  Process schedule vacation distribution jobs.
  """

  use Oban.Worker, queue: :vacation_distribution

  @impl Oban.Worker

  def perform(%Oban.Job{args: args}) do
    require Logger
    Logger.info("job Processed #{inspect(args)}")
    :ok
  end
end

defmodule Draft.VacationDistributionWorker do
  @moduledoc """
  Process scheduled vacation distribution jobs.
  """

  use Oban.Worker, queue: :vacation_distribution, max_attempts: 1
  alias Draft.BasicVacationDistributionRunner

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    BasicVacationDistributionRunner.distribute_vacation_to_group(args)
  end
end

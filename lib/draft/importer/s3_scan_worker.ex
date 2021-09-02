defmodule Draft.Importer.S3ScanWorker do
  @moduledoc """
  Oban worker to scan an S3 bucket for directories, and schedule imports as a separate job.
  """
  use Oban.Worker,
    queue: :importer,
    max_attempts: 1,
    unique: [period: 60, states: [:available, :scheduled, :executing]]

  alias Draft.Importer.S3ImportWorker

  @delimiter "/"

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "bucket" => bucket,
      "prefix" => prefix
    } = args

    ex_aws =
      case args do
        %{"ex_aws" => mod_str} -> Module.safe_concat([mod_str])
        _args -> ExAws
      end

    workers = workers_to_insert(bucket, prefix, ex_aws)

    Draft.Repo.transaction(fn ->
      Enum.each(workers, &Oban.insert/1)
    end)

    :ok
  end

  defp workers_to_insert(bucket, prefix, ex_aws) do
    prefix_with_delimiter =
      if String.ends_with?(prefix, @delimiter) do
        prefix
      else
        prefix <> @delimiter
      end

    %{body: %{common_prefixes: common_prefixes}} =
      ex_aws.request!(
        ExAws.S3.list_objects(bucket, prefix: prefix_with_delimiter, delimiter: "/")
      )

    folders =
      common_prefixes
      |> Enum.map(&Map.get(&1, :prefix))
      |> Enum.sort()

    for folder <- folders do
      S3ImportWorker.new(%{bucket: bucket, prefix: folder})
    end
  end
end

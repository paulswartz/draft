defmodule Draft.Importer.S3ScanWorkerTest do
  use Draft.DataCase, async: true
  use Oban.Testing, repo: Draft.Repo

  alias __MODULE__.FakeAws

  describe "perform/1" do
    test "creates an S3ImportWorker job for each common prefix returned" do
      assert :ok =
               perform_job(Draft.Importer.S3ScanWorker, %{
                 bucket: "bucket",
                 prefix: "prefix",
                 ex_aws: FakeAws
               })

      assert_enqueued(
        worker: Draft.Importer.S3ImportWorker,
        args: %{bucket: "bucket", prefix: "prefix/1"}
      )

      assert_enqueued(
        worker: Draft.Importer.S3ImportWorker,
        args: %{bucket: "bucket", prefix: "prefix/2"}
      )
    end
  end

  defmodule FakeAws do
    @moduledoc """
    Fake responses to AWS requests
    """
    @spec request!(ExAws.Operation.t()) :: map
    def request!(%ExAws.Operation.S3{
          http_method: :get,
          bucket: "bucket",
          params: %{"delimiter" => "/", "prefix" => "prefix/"}
        }) do
      %{
        body: %{
          common_prefixes: [%{prefix: "prefix/1"}, %{prefix: "prefix/2"}]
        }
      }
    end

    def request!(request) do
      raise ExAws.Error, "unknown request, #{inspect(request)}"
    end
  end
end

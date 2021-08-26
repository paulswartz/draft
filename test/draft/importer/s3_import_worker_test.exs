defmodule Draft.Importer.S3ImportWorkerTest do
  use Draft.DataCase, async: true
  use Oban.Testing, repo: Draft.Repo

  import Draft.Importer.S3ImportWorker
  doctest Draft.Importer.S3ImportWorker

  alias __MODULE__.FakeAws

  describe "perform/1" do
    test "fetches files and performs an import from the given prefix" do
      assert :ok =
               perform_job(Draft.Importer.S3ImportWorker, %{
                 bucket: "bucket",
                 prefix: "prefix",
                 ex_aws: FakeAws
               })

      assert length(Repo.all(Draft.DivisionVacationDayQuota)) > 0
      assert length(Repo.all(Draft.DivisionVacationWeekQuota)) > 0
      assert length(Repo.all(Draft.EmployeeVacationQuota)) > 0
      assert length(Repo.all(Draft.EmployeeVacationSelection)) > 0
      assert length(Repo.all(Draft.BidRound)) > 0
      assert length(Repo.all(Draft.BidGroup)) > 0
      assert length(Repo.all(Draft.EmployeeRanking)) > 0
    end
  end

  defmodule FakeAws do
    # mapping from S3-style filenames to the ones in test/support/test_data
    @test_files %{
      "Test-Bid_Round-Group" => "test_rounds.csv",
      "Test-Bid_Session-Roster-Set" => "test_sessions.csv",
      "Test-Roster_Day" => "test_roster_days.csv",
      "Test-Div-Quota-Date" => "test_vac_div_quota_dated.csv",
      "Test-Div-Quota-Week" => "test_vac_div_quota_weekly.csv",
      "Test-Emp-Selection" => "test_vac_emp_selections.csv",
      "Test-Emp-Quota" => "test_vac_emp_quota.csv"
    }

    # list the files in the bucket by prefix
    @spec request!(ExAws.Operation.t()) :: map
    def request!(%ExAws.Operation.S3{
          http_method: :get,
          bucket: "bucket",
          params: %{"prefix" => "prefix" = prefix}
        }) do
      file_contents =
        for {key, fs_file} <- @test_files do
          size = File.stat!(full_path(fs_file)).size

          %{
            key: "#{prefix}/#{key}",
            size: Integer.to_string(size)
          }
        end

      directory_contents = [
        %{key: prefix, size: "0"}
      ]

      %{
        status_code: 200,
        body: %{
          contents: directory_contents ++ file_contents
        }
      }
    end

    # fetch an individual file
    def request!(%ExAws.Operation.S3{
          http_method: :get,
          bucket: "bucket",
          path: "prefix/" <> key
        }) do
      if fs_file = Map.get(@test_files, key) do
        %{status_code: 200, body: File.read!(full_path(fs_file))}
      else
        %{status_code: 404}
      end
    end

    def request!(request) do
      raise ExAws.Error, "unknown request, #{inspect(request)}"
    end

    defp full_path(fs_file) do
      "test/support/test_data/#{fs_file}"
    end
  end
end

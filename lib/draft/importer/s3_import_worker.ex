defmodule Draft.Importer.S3ImportWorker do
  @moduledoc """
  Import a directory from S3.
  """
  use Oban.Worker, queue: :importer, max_attempts: 5, unique: [period: :infinity]
  require Logger

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

    %{body: %{contents: contents}} =
      ex_aws.request!(ExAws.S3.list_objects(bucket, prefix: prefix))

    filenames = for %{key: key, size: size} <- contents, size != "0", do: key

    _ignored =
      Logger.info(
        "files found when scanning s3://#{bucket}/#{prefix} files=#{inspect(filenames)}"
      )

    vacation_quota_setup(bucket, filenames, ex_aws)
    bid_process_setup(bucket, filenames, ex_aws)
  end

  defp bid_process_setup(bucket, filenames, ex_aws) do
    bid_round = best_file(filenames, ["Bid_Round", "Group"])
    bid_session = best_file(filenames, ["Bid_Session", "Roster_Set"])
    roster_day = best_file(filenames, ["Roster_Day"])

    _ignored =
      if bid_round && bid_session && roster_day do
        [bid_round_body, bid_session_body, roster_day_body] =
          bulk_fetch_from_s3!(bucket, [bid_round, bid_session, roster_day], ex_aws)

        Draft.BidProcessSetup.update_bid_process(%{
          Draft.BidRound => {:raw, bid_round_body},
          Draft.BidSession => {:raw, bid_session_body},
          Draft.RosterDay => {:raw, roster_day_body}
        })
      else
        Logger.warn("Unable to find filenames to import BidRoundSetup in s3://#{bucket}")
      end

    :ok
  end

  defp vacation_quota_setup(bucket, filenames, ex_aws) do
    day_quota = best_file(filenames, ["Div", "Quota", "Date"])
    week_quota = best_file(filenames, ["Div", "Quota", "Week"])
    vacation_selection = best_file(filenames, ["Emp", "Selection"])
    vacation_quota = best_file(filenames, ["Emp", "Quota"])

    _ignored =
      if day_quota && week_quota && vacation_selection && vacation_quota do
        [day_quota_body, week_quota_body, vacation_selection_body, vacation_quota_body] =
          bulk_fetch_from_s3!(
            bucket,
            [day_quota, week_quota, vacation_selection, vacation_quota],
            ex_aws
          )

        Draft.VacationQuotaSetup.update_vacation_quota_data([
          {Draft.DivisionVacationDayQuota, {:raw, day_quota_body}},
          {Draft.DivisionVacationWeekQuota, {:raw, week_quota_body}},
          {Draft.EmployeeVacationSelection, {:raw, vacation_selection_body}},
          {Draft.EmployeeVacationQuota, {:raw, vacation_quota_body}}
        ])
      else
        Logger.warn("Unable to find filenames to import VacationQuotaSetup in s3://#{bucket}")
      end

    :ok
  end

  @spec bulk_fetch_from_s3!(String.t(), [String.t()], module()) :: [String.t()]
  def bulk_fetch_from_s3!(bucket, filenames, ex_aws) do
    filenames
    |> Task.async_stream(&fetch_from_s3!(bucket, &1, ex_aws))
    |> Enum.map(fn {:ok, contents} -> contents end)
  end

  @spec fetch_from_s3!(String.t(), String.t(), module()) :: String.t()
  defp fetch_from_s3!(bucket, filename, ex_aws) do
    Logger.debug("fetching s3://#{bucket}/#{filename}")
    %{status_code: 200, body: body} = ex_aws.request!(ExAws.S3.get_object(bucket, filename))
    body
  end

  @doc """
  Given a list of substrings to match, return the most matching filename.

  iex> filenames = ["Div_Quota_Dated.csv", "Div_Quota_Weekly.csv", "Emp_Selections.csv", "Emp_Quota.csv"]
  iex> best_file(filenames, ["Quota", "Dated"])
  "Div_Quota_Dated.csv"
  iex> best_file(filenames, ["Emp", "Quota"])
  "Emp_Quota.csv"
  """
  @spec best_file([String.t(), ...], [String.t(), ...]) :: String.t() | nil
  def best_file(filenames, substrings)
  def best_file([], _substrings), do: nil
  def best_file(_filenames, []), do: nil

  def best_file(filenames, substrings) do
    Enum.max_by(filenames, fn filename ->
      substrings
      |> Enum.filter(fn substring -> String.contains?(filename, substring) end)
      |> length()
    end)
  end
end

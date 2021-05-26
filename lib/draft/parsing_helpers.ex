defmodule Draft.ParsingHelpers do
  @moduledoc """
  Functions useful for parsing formatted strings into the correct type.
  """

  @spec to_date(String.t()) :: Date.t()
  @doc """
  Convert the given formatted date string into a date. Expects date formatted in %m/%d/%y (ex: 1/2/2023)
  """
  def to_date(date_string) do
    date_string
    |> Timex.parse!("{0M}/{0D}/{YYYY}")
    |> Timex.to_date()
  end

  @spec hastus_format_to_utc_datetime(String.t(), String.t()) :: DateTime.t()
  @doc """
  Convert the given formatted date & time string represnting a time in America/NY time
  into a UTC datetime. Expects Date formatted in %m/%d/%y (ex: 1/2/2023) and time formatted in
  %I%M%%p, with the trailing "m" of the meridian marker omitted (ex: 500p for 5PM, 330a for 3:30AM)
  If the time string has a trailing "x", (ex: 330x),
  it represents that time on the following day (ex: 1/2/2023, 330x for 1/3/2023 3:30 AM)
  """
  def hastus_format_to_utc_datetime(date_string, time_string) do
    if String.last(time_string) == "x" do
      base_date_time = String.trim_trailing(time_string, "x")
      time_string = base_date_time <> "a"
      Timex.add(to_utc_datetime(date_string, time_string), Timex.Duration.from_days(1))
    else
      to_utc_datetime(date_string, time_string)
    end
  end

  defp to_utc_datetime(date_string, time_string) do
    (date_string <> String.pad_leading(time_string <> "m", 6, "0") <> " America/New_York")
    |> Timex.parse!("%m/%d/%Y%I%M%p %Z", :strftime)
    |> Timex.Timezone.convert(:utc)
  end
end

defmodule Draft.ParsingHelpers do
  @moduledoc """
  Functions useful for parsing formatted strings into the correct type.
  """

  NimbleCSV.define(PipeSeparatedParser, separator: "\|")

  @spec parse_pipe_separated_file(String.t()) :: Enumerable.t()
  @doc """
  Parse a pipe separated file without headers.
  """
  def parse_pipe_separated_file(filename) do
    filename
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> PipeSeparatedParser.parse_stream(skip_headers: false)
  end

  @spec to_optional_int(String.t() | nil) :: integer() | nil
  @doc """
  Parse the given string into an integer if not nil. Otherwise, returns nil.
  """
  def to_optional_int(maybe_int) do
    if maybe_int == nil do
      nil
    else
      String.to_integer(maybe_int)
    end
  end

  @spec to_optional_date(String.t() | nil) :: Date.t() | nil
  @doc """
  Parse the given string into a date if not nil. Otherwise, returns nil
  """
  def to_optional_date(maybe_date) do
    if maybe_date == nil do
      nil
    else
      to_date(maybe_date)
    end
  end

  @spec to_date(String.t()) :: Date.t()
  @doc """
  Convert the given formatted date string into a date. Expects date formatted in %m/%d/%y (ex: 1/2/2023)
  """
  def to_date(date_string) do
    date_string
    |> Timex.parse!("{0M}/{0D}/{YYYY}")
    |> Timex.to_date()
  end

  @spec to_minutes(String.t()) :: integer()
  @doc """
  Convert the given duration string to the number of minutes it represents. Expects formats %Hh%M
  """
  def to_minutes(duration_string) do
    [hours, minutes] = String.split(duration_string, "h")
    String.to_integer(hours) * 60 + String.to_integer(minutes)
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

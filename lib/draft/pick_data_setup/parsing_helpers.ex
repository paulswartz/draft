defmodule Draft.PickDataSetup.ParsingHelpers do
  @moduledoc """
  Functions useful for parsing formatted strings into the correct type.
  """

  @spec to_date(String.t()) :: Date.t()
  def to_date(date_string) do
    date_string
    |> Timex.parse!("{0M}/{0D}/{YYYY}")
    |> Timex.to_date()
  end

  @spec to_utc_datetime(String.t(), String.t()) :: DateTime.t()
  @doc """
  Convert the given formatted date & time string represnting a time in America/NY time
  into a UTC datetime. Expects Date formatted in %m/%d/%y (ex: 1/2/2023) and time formatted in
  %I%M%%p, with the trailing "m" of the meridian marker omitted (ex: 500p for 5PM, 330a for 3:30AM)


  """
  def to_utc_datetime(date_string, time_string) do
    (date_string <> String.pad_leading(time_string <> "m", 6, "0") <> " America/New_York")
    |> Timex.parse!("%m/%d/%Y%I%M%p %Z", :strftime)
    |> Timex.Timezone.convert(:utc)
  end
end

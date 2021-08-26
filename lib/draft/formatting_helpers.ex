defmodule Draft.FormattingHelpers do
  @moduledoc """
  Format values in HASTUS-accepted representation.
  """
  @spec to_date_string(Date.t()) :: String.t()
  @doc """
  Convert the given date into a String formatted %m/%d/%y

  iex> FormattingHelpers.to_date_string(~D[2021-08-23])
  "08/23/2021"
  """
  def to_date_string(date) do
    Timex.format!(date, "{0M}/{0D}/{YYYY}")
  end

  @spec to_day_of_week(Date.t()) :: String.t()
  @doc """
  Get the day of the week for the given date.

  iex> FormattingHelpers.to_day_of_week(~D[2021-08-23])
  "Monday"
  """
  def to_day_of_week(date) do
    Timex.format!(date, "%A", :strftime)
  end
end

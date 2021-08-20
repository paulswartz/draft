defmodule Draft.FormattingHelpers do
  @moduledoc """
  Format values in HASTUS-accepted representation.
  """
  @spec to_date_string(Date.t()) :: String.t()
  @doc """
  Convert the given date into a String formatted %m/%d/%y (ex: 1/2/2023)
  """
  def to_date_string(date) do
    Timex.format!(date, "{0M}/{0D}/{YYYY}")
  end

  @spec to_day_of_week(Date.t()) :: String.t()
  @doc """
  Get the day of the week for the given date. Ex: to_day_of_week(~D[2021-08-23]) would return "Monday"
  """
  def to_day_of_week(date) do
    Timex.format!(date, "%u")
  end
end

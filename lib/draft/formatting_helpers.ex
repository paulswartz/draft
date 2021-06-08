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
end

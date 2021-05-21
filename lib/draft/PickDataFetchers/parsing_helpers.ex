defmodule Draft.PickSetup.ParsingHelpers do
  def to_date(dateString) do
    dateString
    |> Timex.parse!("{0M}/{0D}/{YYYY}")
    |> Timex.to_date()
  end

  def to_datetime(dateString, timeString) do
    (dateString <> String.pad_leading(timeString <> "m", 6, "0") <> " America/New_York")
    |> Timex.parse!("%m/%d/%Y%I%M%p %Z", :strftime)
    |> Timex.Timezone.convert(:utc)
  end
end

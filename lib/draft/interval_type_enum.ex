defmodule Draft.IntervalTypeEnum do
  @moduledoc """
  Represent supported intervals of vacation.
  """
  use EctoEnum, week: "week", day: "day"
end

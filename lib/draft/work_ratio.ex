defmodule Draft.WorkRatio do
  @moduledoc """
  The ratio of days worked to days off in a week.
  Ex: 5/2 is 5 days worked, 2 days off.
  The ratio may be "unspecified" in the case of the VR roster.
  """
  use EctoEnum, five_two: "5/2", four_three: "4/3", unspecified: nil
end

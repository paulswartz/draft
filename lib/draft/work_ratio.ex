defmodule Draft.WorkRatio do
  @moduledoc """
  The ratio of days worked to days off in a week.
  Ex: 5/2 is 5 days worked, 2 days off.
  The ratio may be "unspecified" in the case of the VR roster.
  """
  use EctoEnum, five_two: "5/2", four_three: "4/3", unspecified: nil

  @spec from_hastus(String.t()) :: t()
  @doc """
  Convert hastus given string into correct enum
  """
  def from_hastus("5/2") do
    :five_two
  end

  def from_hastus("4/3") do
    :four_three
  end

  def from_hastus("") do
    :unspecified
  end
end

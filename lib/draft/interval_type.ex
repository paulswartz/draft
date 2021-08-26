defmodule Draft.IntervalType do
  @moduledoc """
  Represent supported intervals of vacation.
  """
  use EctoEnum, week: "week", day: "day"

  @spec from_hastus_session_allowed(String.t() | nil) :: t() | nil
  @doc """
  Return the appropriate vacation interval from "type allowed" field of the HASTUS
  Session record. Returns nil if the type allowed is nil, indicating that a session
  does not support vacation picking.
  """
  def from_hastus_session_allowed(vacation_type_allowed)

  def from_hastus_session_allowed("Only weekly") do
    :week
  end

  def from_hastus_session_allowed("Only dated") do
    :day
  end

  def from_hastus_session_allowed("") do
    nil
  end

  def from_hastus_session_allowed(nil) do
    nil
  end
end

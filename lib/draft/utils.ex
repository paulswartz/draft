defmodule Draft.Utils do
  @moduledoc """
  Helper functions
  """
  @spec compare_date_to_range(Date.t(), Date.t(), Date.t()) ::
          :before_range | :in_range | :after_range
  @doc """
  Determine where the given date falls relative to the given range (range_start_date_excl, range_end_date_incl]
  """
  def compare_date_to_range(date, range_start_date_excl, range_end_date_incl) do
    case Date.compare(date, range_start_date_excl) do
      :gt ->
        if Date.compare(date, range_end_date_incl) == :gt do
          :after_range
        else
          :in_range
        end

      _lt_or_eq ->
        :before_range
    end
  end

  @spec percent_round_up(number(), 0..100) :: integer()
  @doc """
  Take a percentage of the given value, rounded up to the nearest integer.

  iex> Draft.Utils.percent_round_up(10, 41)
  5
  iex> Draft.Utils.percent_round_up(10, 100)
  10
  iex> Draft.Utils.percent_round_up(10, 0)
  0
  """
  def percent_round_up(_value, 0) do
    0
  end

  def percent_round_up(value, 100) do
    value
  end

  def percent_round_up(value, percent) do
    value
    |> (&(&1 * percent)).()
    |> Decimal.div(100)
    |> Decimal.round(0, :up)
    |> Decimal.to_integer()
  end
end

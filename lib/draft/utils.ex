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
end

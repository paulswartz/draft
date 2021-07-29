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

  @spec record_for_bulk_insert(struct()) :: map()
  @doc """
  Converts a record into a plain map containing only the fields specified in the record's schema.
  Adds the inserted_at and updated_at fields, which are not populated by `Repo.insert_all`
  """

  def record_for_bulk_insert(record) do
    timestamp = DateTime.truncate(DateTime.utc_now(), :second)
    %record_type{} = record

    record
    |> Map.take(record_type.__schema__(:fields))
    |> Map.merge(%{inserted_at: timestamp, updated_at: timestamp})
  end
end

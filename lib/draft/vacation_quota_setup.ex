defmodule Draft.VacationQuotaSetup do
  @moduledoc """
  Setup the bid rounds -- parse data from an extract and store round / group / employee data in the database.
  """

  import Ecto.Query, warn: false

  alias Draft.DivisionVacationQuotaDated
  alias Draft.DivisionVacationQuotaWeek
  alias Draft.EmployeeVacationQuota
  alias Draft.EmployeeVacationSelection
  alias Draft.Parsable
  alias Draft.ParsingHelpers
  alias Draft.Repo

  @spec update_vacation_quota_data(%{module() => String.t()}) :: [{integer(), nil | [term()]}]
  @doc """
  Reads bid round, group, and employee data from the given file and stores it in the database.
  If there was already data stored for any round present in the file, that data will be removed & re-inserted.
  """
  def update_vacation_quota_data(
        %{
          EmployeeVacationQuota => _emp_vacation_quota_file_loc,
          EmployeeVacationSelection => _emp_vacation_selection_file_loc,
          DivisionVacationQuotaDated => _division_vacation_quota_date_file_loc,
          DivisionVacationQuotaWeek => _division_vacation_quota_week_file_loc
        } = file_map
      ) do
    parsed_records =
      file_map
      |> Map.take([
        EmployeeVacationQuota,
        EmployeeVacationSelection,
        DivisionVacationQuotaDated,
        DivisionVacationQuotaWeek
      ])
      |> Enum.into(%{}, fn {record_type, file_name} ->
        {record_type, ParsingHelpers.parse_pipe_separated_file(file_name)}
      end)
      |> Enum.into(%{}, fn {record_type, parsed_parts} ->
        {record_type, Stream.map(parsed_parts, &Parsable.from_parts(record_type, &1))}
      end)

    Enum.map(parsed_records, fn {record_type, records} ->
      Repo.transaction(fn ->
        delete_all(record_type)
        insert_all_records(records)
      end)
    end)
  end

  defp delete_all(record_type) do
    Repo.delete_all(from(r in record_type))
  end

  defp insert_all_records(records) do
    Enum.each(records, &Repo.insert(&1))
  end
end

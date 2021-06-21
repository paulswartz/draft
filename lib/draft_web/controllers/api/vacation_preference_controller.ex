defmodule DraftWeb.API.VacationPreferenceController do
  use DraftWeb, :controller
  alias Draft.EmployeeVacationPreferenceSet
  alias Draft.EmployeeVacationPreference
  alias Draft.Repo

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, preference_set) do

    require Logger
    Logger.debug("PREFERENCE SET")
    Logger.debug(preference_set)

    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

      vacation_weeks = Map.get(preference_set, "weeks", [])
      |> Enum.map(&format_week_preference(&1))


      require Logger
      Logger.debug("VACATION WEEKS")
      Logger.debug(vacation_weeks)
    new_preferences = %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(:vacation_preferences, vacation_weeks)


    preferences = EmployeeVacationPreferenceSet.changeset(%EmployeeVacationPreferenceSet{}, new_preferences)
    response = Repo.insert!(preferences)
    Logger.debug(response)

    json(conn, response)
  end

  defp format_week_preference(week) do
    {:ok, start_date} = Date.from_iso8601(Map.get(week, "start_date"))
    %{start_date: start_date, end_date: Date.add(start_date, 7), preference_rank: Map.get(week, "rank"), interval_type: "week"}
  end
end

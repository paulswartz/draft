defmodule DraftWeb.API.VacationPreferenceController do
  use DraftWeb, :controller
  alias Draft.EmployeeVacationPreferenceSet

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, _params) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    latest_preferences =
      EmployeeVacationPreferenceSet.get_latest_preferences(
        pick_overview.process_id,
        pick_overview.round_id,
        pick_overview.employee_id
      )

    json(conn, %{
      data: group_vacation_preferences(latest_preferences)
    })
  end

  @spec group_vacation_preferences(EmployeeVacationPreferenceSet.t() | nil) :: map()
  defp group_vacation_preferences(preference_set)

  defp group_vacation_preferences(nil) do
    %{
      weeks: [],
      days: []
    }
  end

  defp group_vacation_preferences(preference_set) do
    grouped_preferences =
      Enum.group_by(preference_set.vacation_preferences, fn p -> p.interval_type end, fn p ->
        p
      end)

    %{
      weeks: Map.get(grouped_preferences, "week", []),
      days: Map.get(grouped_preferences, "day", [])
    }
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, preference_set) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    vacation_weeks =
      Map.get(preference_set, "weeks", [])
      |> Enum.map(&format_week_preference(&1))

    vacation_days =
      Map.get(preference_set, "days", [])
      |> Enum.map(&format_day_preference(&1))

    preference_attrs =
      %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(:vacation_preferences, vacation_weeks ++ vacation_days)

    new_preference_set = EmployeeVacationPreferenceSet.create(preference_attrs)

    case new_preference_set do
      {:ok, preference_set} ->
        json(conn, preference_set)

      {:error, error_changeset} ->
        conn
        |> put_status(500)
        |> json(error_changeset.errors)
    end
  end

  defp format_week_preference(week) do
    {:ok, start_date} = Date.from_iso8601(Map.get(week, "start_date"))

    %{
      start_date: start_date,
      end_date: Date.add(start_date, 7),
      preference_rank: Map.get(week, "rank"),
      interval_type: "week"
    }
  end

  defp format_day_preference(day) do
    {:ok, start_date} = Date.from_iso8601(Map.get(day, "start_date"))

    %{
      start_date: start_date,
      end_date: start_date,
      preference_rank: Map.get(day, "rank"),
      interval_type: "day"
    }
  end
end

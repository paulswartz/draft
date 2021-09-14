defmodule DraftWeb.API.VacationPreferenceController do
  use DraftWeb, :controller
  alias Draft.EmployeeVacationPreferenceSet

  @spec show_latest(Plug.Conn.t(), map) :: Plug.Conn.t()
  @doc """
  Return the latest vacation preferences of the latest pick session the employee is participating in.
  """
  def show_latest(conn, _params) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    latest_preferences =
      case EmployeeVacationPreferenceSet.latest_preference_set(
             pick_overview.process_id,
             pick_overview.round_id,
             pick_overview.employee_id
           ) do
        nil -> %{id: nil, vacation_preferences: []}
        prefs -> prefs
      end

    build_json_response(conn, latest_preferences)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  @doc """
  Insert a new preference set
  """
  def create(conn, %{"preferences" => preferences}) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    preference_set_creation_result =
      %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(
        :vacation_preferences,
        to_vacation_preferences(pick_overview.interval_type, preferences)
      )
      |> EmployeeVacationPreferenceSet.create()

    build_json_response(conn, preference_set_creation_result)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  @doc """
  Update a preference set -- inserts a new preference set with a reference to the previous one.
  """
  def update(conn, %{
        "previous_preference_set_id" => previous_preference_set_id,
        "preferences" => preferences
      }) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    preference_set_update_result =
      %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(:previous_preference_set_id, previous_preference_set_id)
      |> Map.put(
        :vacation_preferences,
        to_vacation_preferences(pick_overview.interval_type, preferences)
      )
      |> EmployeeVacationPreferenceSet.update()

    build_json_response(conn, preference_set_update_result)
  end

  defp build_json_response(conn, result)

  defp build_json_response(conn, {:ok, preference_set}) do
    build_json_response(conn, preference_set)
  end

  defp build_json_response(conn, {:error, error_changeset}) do
    conn
    |> put_status(500)
    |> json(%{
      data: Ecto.Changeset.traverse_errors(error_changeset, &format_error_messages(&1))
    })
  end

  defp build_json_response(conn, preference_set) do
    json(conn, %{
      data: %{
        id: preference_set.id,
        preferences:
          Enum.map(
            preference_set.vacation_preferences,
            &Map.take(&1, [:start_date, :end_date, :rank])
          )
      }
    })
  end

  defp format_error_messages({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp to_vacation_preferences(interval_type, preference_set) do
    Enum.map(preference_set, &to_vacation_preference(interval_type, &1))
  end

  defp to_vacation_preference(interval_type, preference) do
    {:ok, start_date} = Date.from_iso8601(Map.get(preference, "start_date"))
    {:ok, end_date} = Date.from_iso8601(Map.get(preference, "end_date"))

    %{
      start_date: start_date,
      end_date: end_date,
      rank: Map.get(preference, "rank"),
      interval_type: interval_type
    }
  end
end

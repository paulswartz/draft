defmodule DraftWeb.API.VacationPreferenceController do
  use DraftWeb, :controller
  alias Draft.EmployeeVacationPreference
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
      EmployeeVacationPreferenceSet.latest_preference_set(
        pick_overview.process_id,
        pick_overview.round_id,
        pick_overview.employee_id
      )

    json(conn, %{
      data: group_vacation_preferences(latest_preferences)
    })
  end

  @spec group_vacation_preferences(EmployeeVacationPreferenceSet.t() | nil) :: %{
          required(:id) => integer(),
          required(:weeks) => [EmployeeVacationPreference.t()],
          required(:days) => [EmployeeVacationPreference.t()]
        }
  defp group_vacation_preferences(preference_set)

  defp group_vacation_preferences(nil) do
    %{id: nil, weeks: [], days: []}
  end

  defp group_vacation_preferences(preference_set) do
    grouped_preferences =
      Enum.group_by(preference_set.vacation_preferences, fn p -> p.interval_type end, fn p ->
        p
      end)

    %{
      id: preference_set.id,
      weeks: Map.get(grouped_preferences, :week, []),
      days: Map.get(grouped_preferences, :day, [])
    }
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  @doc """
  Insert a new preference set
  """
  def create(conn, preference_set) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    preference_set_creation_result =
      %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(:vacation_preferences, to_vacation_preferences(preference_set))
      |> EmployeeVacationPreferenceSet.create()

    build_json_response(conn, preference_set_creation_result)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  @doc """
  Update a preference set -- inserts a new preference set with a reference to the previous one.
  """
  def update(conn, preference_set) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    preference_set_update_result =
      %{}
      |> Map.put(:round_id, pick_overview.round_id)
      |> Map.put(:process_id, pick_overview.process_id)
      |> Map.put(:employee_id, pick_overview.employee_id)
      |> Map.put(
        :previous_preference_set_id,
        Map.get(preference_set, "previous_preference_set_id")
      )
      |> Map.put(:vacation_preferences, to_vacation_preferences(preference_set))
      |> EmployeeVacationPreferenceSet.update()

    build_json_response(conn, preference_set_update_result)
  end

  defp build_json_response(conn, result)

  defp build_json_response(conn, {:ok, preference_set}) do
    json(conn, %{data: group_vacation_preferences(preference_set)})
  end

  defp build_json_response(conn, {:error, error_changeset}) do
    conn
    |> put_status(500)
    |> json(%{
      data: Ecto.Changeset.traverse_errors(error_changeset, &format_error_messages(&1))
    })
  end

  defp format_error_messages({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end

  defp to_vacation_preferences(preference_set) do
    vacation_weeks =
      preference_set
      |> Map.get("weeks", [])
      |> Enum.map(&to_vacation_preference(:week, &1))

    vacation_days =
      preference_set
      |> Map.get("days", [])
      |> Enum.map(&to_vacation_preference(:day, &1))

    vacation_weeks ++ vacation_days
  end

  defp to_vacation_preference(interval_type, inverval)

  defp to_vacation_preference(:week, week) do
    {:ok, start_date} = Date.from_iso8601(Map.get(week, "start_date"))

    %{
      start_date: start_date,
      end_date: Map.get(week, "end_date"),
      rank: Map.get(week, "rank"),
      interval_type: :week
    }
  end

  defp to_vacation_preference(:day, day) do
    {:ok, start_date} = Date.from_iso8601(Map.get(day, "start_date"))
    {:ok, end_date} = Date.from_iso8601(Map.get(day, "end_date"))

    %{
      start_date: start_date,
      end_date: end_date,
      rank: Map.get(day, "rank"),
      interval_type: :day
    }
  end
end

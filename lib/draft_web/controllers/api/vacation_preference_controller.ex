defmodule DraftWeb.API.VacationPreferenceController do
  use DraftWeb, :controller
  alias Draft.EmployeeVacationPreferenceSet

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, preference_set) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    EmployeeVacationPreferenceSet.changeset(%EmployeeVacationPreferenceSet{})

    json(conn, %{data: all_available_vacation})
  end
end

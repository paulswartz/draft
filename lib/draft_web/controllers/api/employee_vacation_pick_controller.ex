defmodule DraftWeb.API.EmployeeVacationPickController do
  use DraftWeb, :controller

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, _params) do
    latest_pick_overview =
      Draft.EmployeeVacationPickOverview.open_round(get_session(conn, :user_id))

    json(conn, %{data: latest_pick_overview})
  end
end

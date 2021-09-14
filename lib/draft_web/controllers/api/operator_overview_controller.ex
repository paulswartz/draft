defmodule DraftWeb.API.OperatorOverviewController do
  use DraftWeb, :controller

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, _params) do
    latest_pick_overview = Draft.EmployeePickOverview.get_latest(get_session(conn, :user_id))
    json(conn, %{data: latest_pick_overview})
  end
end

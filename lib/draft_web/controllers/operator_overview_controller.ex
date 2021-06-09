defmodule DraftWeb.OperatorOverviewController do
  use DraftWeb, :controller

  @spec show(Plug.Conn.t(), any) :: Plug.Conn.t()
  def show(conn, _params) do
    latest_ranking = Draft.EmployeeRanking.get_latest_ranking(get_session(conn, :user_id))
    render(conn, "show.html", latest_ranking)
  end
end

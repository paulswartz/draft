defmodule DraftWeb.OperatorOverviewController do
  use DraftWeb, :controller

  alias DraftWeb.AuthManager
  alias DraftWeb.Router.Helpers

  def show(conn, _params) do
    logged_in_user = AuthManager.Plug.current_resource(conn)
    latest_ranking = Draft.EmployeeRanking.get_latest_ranking(get_session(conn, :user_id))
    json(conn, Map.put(latest_ranking, "admin_username", logged_in_user))
  end
end

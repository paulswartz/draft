defmodule DraftWeb.SpoofUserController do
  use DraftWeb, :controller

@spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
def index(conn, _params) do
  render(conn, "index.html")
end

@spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
def create(conn, %{"user" => credentials}) do
  badge_number = Map.get(credentials, "badge_number")
  case Draft.EmployeeRanking.get_latest_ranking(badge_number) do
    nil ->
      conn
      |> put_flash(:error, "No record of employee with that badge number. Please try again.")
      |> render("index.html")
    employee_ranking ->
       conn
    |> put_session(:user_id, employee_ranking.employee_id)
    |> configure_session(renew: true)
    |> redirect(to: Routes.operator_overview_path(conn, :show))



  end
end
end

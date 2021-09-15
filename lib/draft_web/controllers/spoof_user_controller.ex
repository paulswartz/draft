defmodule DraftWeb.SpoofUserController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, _params) do
    render(conn, "show.html")
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"user" => credentials}) do
    employee_id = Map.get(credentials, "badge_number")

    if Draft.EmployeeRanking.valid_employee_id?(employee_id) do
      conn
      |> put_session(:user_id, employee_id)
      |> configure_session(renew: true)
      |> redirect(to: Routes.spoof_user_path(conn, :show))
    else
      conn
      |> put_flash(:error, "No record of employee with that badge number. Please try again.")
      |> render("index.html")
    end
  end
end

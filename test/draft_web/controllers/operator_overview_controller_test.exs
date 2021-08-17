defmodule DraftWeb.OperatorOverviewControllerTest do
  use DraftWeb.ConnCase, async: true
  @tag :authenticated
  test "GET /admin/spoof/operator as non-admin results in redirect", %{conn: conn} do
    conn = get(conn, "/admin/spoof/operator")
    assert redirected_to(conn) == "/"
  end

  @tag :authenticated_admin
  test "GET /admin/spoof with badge number that exists", %{conn: conn} do
    Draft.Factory.insert_round_with_employees(1)

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> get("/admin/spoof/operator")

    assert html_response(conn, 200) =~ "Badge Number: 00001"
  end
end

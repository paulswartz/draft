defmodule DraftWeb.AdminControllerTest do
  use DraftWeb.ConnCase

  @tag :authenticated_admin
  test "GET /admin as an admin", %{conn: conn} do
    conn = get(conn, "/admin")
    assert html_response(conn, 200) =~ "Admin only view!"
  end

  test "GET /admin as non-admin results in redirect to login", %{conn: conn} do
    conn = get(conn, "/admin")
    assert redirected_to(conn) == "/auth/cognito"
  end
end

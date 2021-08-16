defmodule DraftWeb.SpoofUserControllerTest do
  use DraftWeb.ConnCase
  @tag :authenticated_admin
  test "GET /admin/spoof", %{conn: conn} do
    conn = get(conn, "/admin/spoof")
    assert html_response(conn, 200) =~ "Input the badge number of the user to spoof"
  end

  @tag :authenticated
  test "GET /admin/spoof as non-admin results in redirect", %{conn: conn} do
    conn = get(conn, "/admin/spoof")
    assert redirected_to(conn) == "/"
  end

  @tag :authenticated_admin
  test "POST /admin/spoof with badge number that doesn't exist", %{conn: conn} do
    conn = post(conn, "/admin/spoof", %{"user" => %{"badge_number" => "00001"}})
    assert html_response(conn, 200) =~ "No record of employee with that badge number."
  end

  @tag :authenticated_admin
  test "POST /admin/spoof with badge number that exists", %{conn: conn} do
    Draft.Factory.insert_round_with_employees(1)
    conn = post(conn, "/admin/spoof", %{"user" => %{"badge_number" => "00001"}})
    assert redirected_to(conn) == "/admin/spoof/operator"
  end

  @tag :authenticated
  test "POST /admin/spoof as non-admin results in redirect", %{conn: conn} do
    conn = post(conn, "/admin/spoof")
    assert redirected_to(conn) == "/"
  end
end

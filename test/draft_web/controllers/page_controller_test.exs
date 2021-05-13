defmodule DraftWeb.PageControllerTest do
  use DraftWeb.ConnCase

  @tag :authenticated
  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome!"
  end
end

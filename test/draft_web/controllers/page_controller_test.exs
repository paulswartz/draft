defmodule DraftWeb.PageControllerTest do
  use DraftWeb.ConnCase

  @tag :authenticated
  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Draft"
  end

  @tag :authenticated
  test "GET / with HTTP redirects to HTTPS", %{conn: conn} do
    conn = conn |> Plug.Conn.put_req_header("x-forwarded-proto", "http") |> get("/")

    location_header = Enum.find(conn.resp_headers, fn {key, _value} -> key == "location" end)
    {"location", url} = location_header
    assert url =~ "https"

    assert response(conn, 301)
  end

  @tag :authenticated
  test "GET / with HTTPS results in 200", %{conn: conn} do
    conn = conn |> Plug.Conn.put_req_header("x-forwarded-proto", "https") |> get("/")
    assert response(conn, 200)
  end
end

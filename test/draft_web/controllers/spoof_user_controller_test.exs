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
    Draft.Factory.insert_round_with_employees(
      %{
        rank: 1,
        round_id: "round_1",
        process_id: "process_1",
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        rating_period_start_date: ~D[2021-04-01],
        rating_period_end_date: ~D[2021-05-01]
      },
      %{
        employee_count: 1,
        group_size: 10
      }
    )

    conn = post(conn, "/admin/spoof", %{"user" => %{"badge_number" => "00001"}})
    assert redirected_to(conn) == "/admin/spoof/operator"
  end

  @tag :authenticated
  test "POST /admin/spoof as non-admin results in redirect", %{conn: conn} do
    conn = post(conn, "/admin/spoof")
    assert redirected_to(conn) == "/"
  end
end

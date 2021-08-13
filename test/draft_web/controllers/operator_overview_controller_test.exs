defmodule DraftWeb.OperatorOverviewControllerTest do
  use DraftWeb.ConnCase, async: true
  @tag :authenticated
  test "GET /admin/spoof/operator as non-admin results in redirect", %{conn: conn} do
    conn = get(conn, "/admin/spoof/operator")
    assert redirected_to(conn) == "/"
  end

  @tag :authenticated_admin
  test "GET /admin/spoof with badge number that exists", %{conn: conn} do
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

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> get("/admin/spoof/operator")

    assert html_response(conn, 200) =~ "Badge Number: 00001"
  end
end

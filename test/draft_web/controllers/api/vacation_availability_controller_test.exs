defmodule DraftWeb.VacationAvailabilityControllerTest do
  use DraftWeb.ConnCase
  import Draft.Factory

  describe "GET /api/vacation_availability" do
    @tag :authenticated
    test "Returns expected availability for weeks", %{conn: conn} do
      insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_1",
          round_id: "vacation_1",
          division_id: "101"
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      conn =
        conn
        |> put_session(:user_id, "00001")
        |> get("/api/vacation_availability")

      assert json_response(conn, 200)["data"] ==
               [
                 %{
                   "end_date" => "2021-02-07",
                   "quota" => 1,
                   "start_date" => "2021-02-01",
                   "preference_rank" => nil
                 }
               ]
    end

    @tag :authenticated
    test "Returns expected availability for DAYS", %{conn: conn} do
      insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_1",
          round_id: "vacation_1",
          division_id: "101"
        },
        %{
          employee_count: 2,
          group_size: 10
        },
        %{type: :vacation, type_allowed: :day}
      )

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      conn =
        conn
        |> put_session(:user_id, "00001")
        |> get("/api/vacation_availability")

      assert json_response(conn, 200)["data"] ==
               [
                 %{
                   "end_date" => "2021-02-01",
                   "quota" => 1,
                   "start_date" => "2021-02-01",
                   "preference_rank" => nil
                 }
               ]
    end

    test "when not authed is redirected to login", %{conn: conn} do
      conn = get(conn, "/api/vacation_availability")
      assert redirected_to(conn) == "/auth/cognito"
    end
  end
end

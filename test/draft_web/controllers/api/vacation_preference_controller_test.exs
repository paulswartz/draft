defmodule DraftWeb.VacatoinPreferenceControllerTest do
  use DraftWeb.ConnCase
  import Draft.Factory
  alias Draft.Repo
  alias Draft.EmployeeVacationPreference
  alias Draft.EmployeeVacationPreferenceSet

  @tag :authenticated
  test "GET /api/vacation/preferences is successful when preferences present", %{conn: conn} do
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
        employee_count: 1,
        group_size: 10
      }
    )

    Repo.insert!(%EmployeeVacationPreferenceSet{
      process_id: "process_1",
      round_id: "vacation_1",
      employee_id: "00001",
      vacation_preferences: [
        %EmployeeVacationPreference{
          start_date: ~D[2021-02-01],
          end_date: ~D[2021-02-07],
          preference_rank: 1,
          interval_type: "week"
        },
        %EmployeeVacationPreference{
          start_date: ~D[2021-02-08],
          end_date: ~D[2021-02-14],
          preference_rank: 2,
          interval_type: "week"
        },
        %EmployeeVacationPreference{
          start_date: ~D[2021-02-08],
          end_date: ~D[2021-02-08],
          preference_rank: 1,
          interval_type: "day"
        }
      ]
    })

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> get("/api/vacation/preferences")

    assert %{
             "days" => [
               %{"start_date" => "2021-02-08", "preference_rank" => 1, "end_date" => "2021-02-08"}
             ],
             "weeks" => [
               %{
                 "start_date" => "2021-02-01",
                 "end_date" => "2021-02-07",
                 "preference_rank" => 1
               },
               %{"start_date" => "2021-02-08", "end_date" => "2021-02-14", "preference_rank" => 2}
             ]
           } = json_response(conn, 200)["data"]
  end

  @tag :authenticated
  test "GET /api/vacation/preferences is successful when no preferences present", %{conn: conn} do
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
        employee_count: 1,
        group_size: 10
      }
    )

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> get("/api/vacation/preferences")

    assert %{
             "days" => [],
             "weeks" => []
           } = json_response(conn, 200)["data"]
  end

  test "GET /vacation/preferences when not authed is redirected to login", %{conn: conn} do
    conn = get(conn, "/api/vacation/preferences")
    assert redirected_to(conn) == "/auth/cognito"
  end
end

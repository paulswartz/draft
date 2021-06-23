defmodule DraftWeb.VacationPreferenceControllerTest do
  use DraftWeb.ConnCase
  import Draft.Factory
  alias Draft.EmployeeVacationPreference
  alias Draft.EmployeeVacationPreferenceSet
  alias Draft.Repo

  @tag :authenticated
  test "GET /api/vacation/preferences/latest is successful when preferences present", %{
    conn: conn
  } do
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
          rank: 1,
          interval_type: "week"
        },
        %EmployeeVacationPreference{
          start_date: ~D[2021-02-08],
          end_date: ~D[2021-02-14],
          rank: 2,
          interval_type: "week"
        },
        %EmployeeVacationPreference{
          start_date: ~D[2021-02-08],
          end_date: ~D[2021-02-08],
          rank: 1,
          interval_type: "day"
        }
      ]
    })

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> get("/api/vacation/preferences/latest")

    assert %{
             "days" => [
               %{"start_date" => "2021-02-08", "rank" => 1, "end_date" => "2021-02-08"}
             ],
             "weeks" => [
               %{
                 "start_date" => "2021-02-01",
                 "end_date" => "2021-02-07",
                 "rank" => 1
               },
               %{"start_date" => "2021-02-08", "end_date" => "2021-02-14", "rank" => 2}
             ]
           } = json_response(conn, 200)["data"]
  end

  @tag :authenticated
  test "GET /api/vacation/preferences/latest is successful when no preferences present", %{
    conn: conn
  } do
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
      |> get("/api/vacation/preferences/latest")

    assert %{
             "days" => [],
             "weeks" => []
           } = json_response(conn, 200)["data"]
  end

  test "GET /vacation/preferences/latest when not authed is redirected to login", %{conn: conn} do
    conn = get(conn, "/api/vacation/preferences/latest")
    assert redirected_to(conn) == "/auth/cognito"
  end

  @tag :authenticated
  test "POST /api/vacation/preferences is successful when preferences valid", %{conn: conn} do
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
      |> post("/api/vacation/preferences", %{
        "days" => [
          %{"start_date" => "2021-02-08", "rank" => 1}
        ],
        "weeks" => [
          %{
            "start_date" => "2021-02-01",
            "rank" => 1
          },
          %{"start_date" => "2021-02-08", "rank" => 2}
        ]
      })

    assert %{
             "days" => [
               %{"start_date" => "2021-02-08", "rank" => 1, "end_date" => "2021-02-08"}
             ],
             "weeks" => [
               %{
                 "start_date" => "2021-02-01",
                 "end_date" => "2021-02-07",
                 "rank" => 1
               },
               %{"start_date" => "2021-02-08", "end_date" => "2021-02-14", "rank" => 2}
             ]
           } = json_response(conn, 200)["data"]
  end

  @tag :authenticated
  test "POST /api/vacation/preferences returns 500 when preferences are invalid", %{conn: conn} do
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
      |> post("/api/vacation/preferences", %{
        "days" => [],
        "weeks" => [
          %{
            "start_date" => "2021-02-01",
            "rank" => 1
          },
          %{"start_date" => "2021-02-01", "rank" => 2}
        ]
      })

    assert %{
             "data" => %{
               "vacation_preferences" => [
                 %{},
                 %{"preference_set_id" => ["has already been taken"]}
               ]
             }
           } = json_response(conn, 500)
  end

  test "POST api/vacation/preferences when not authed is redirected to login", %{conn: conn} do
    conn = post(conn, "/api/vacation/preferences")
    assert redirected_to(conn) == "/auth/cognito"
  end

  @tag :authenticated
  test "PUT /api/vacation/preferences/id is successful when preferences valid", %{conn: conn} do
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

    {:ok, %EmployeeVacationPreferenceSet{id: previous_id}} =
      EmployeeVacationPreferenceSet.create(%{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %{
            start_date: ~D[2021-02-01],
            end_date: ~D[2021-02-07],
            rank: 1,
            interval_type: "week"
          }
        ]
      })

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> put("/api/vacation/preferences/#{previous_id}", %{
        "days" => [
          %{"start_date" => "2021-02-08", "rank" => 1}
        ],
        "weeks" => [
          %{
            "start_date" => "2021-02-01",
            "rank" => 1
          },
          %{"start_date" => "2021-02-08", "rank" => 2}
        ]
      })

    assert %{
             "days" => [
               %{"start_date" => "2021-02-08", "rank" => 1, "end_date" => "2021-02-08"}
             ],
             "weeks" => [
               %{
                 "start_date" => "2021-02-01",
                 "end_date" => "2021-02-07",
                 "rank" => 1
               },
               %{"start_date" => "2021-02-08", "end_date" => "2021-02-14", "rank" => 2}
             ]
           } = json_response(conn, 200)["data"]
  end

  @tag :authenticated
  test "PUT /api/vacation/preferences/id returns 500 when preference set invalid", %{conn: conn} do
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

    {:ok, %EmployeeVacationPreferenceSet{id: previous_id_different_employee}} =
      EmployeeVacationPreferenceSet.create(%{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00002",
        vacation_preferences: [
          %{
            start_date: ~D[2021-02-01],
            end_date: ~D[2021-02-07],
            rank: 1,
            interval_type: "week"
          }
        ]
      })

    conn =
      conn
      |> put_session(:user_id, "00001")
      |> put("/api/vacation/preferences/#{previous_id_different_employee}", %{
        "days" => [
          %{"start_date" => "2021-02-08", "rank" => 1}
        ],
        "weeks" => [
          %{
            "start_date" => "2021-02-01",
            "rank" => 1
          },
          %{"start_date" => "2021-02-08", "rank" => 2}
        ]
      })

    assert %{"data" => %{"previous_preference_set_id" => _error_message}} =
             json_response(conn, 500)
  end
end

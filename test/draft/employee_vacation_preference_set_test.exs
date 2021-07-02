defmodule Draft.EmployeeVacationPreferenceSetTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationPreference
  alias Draft.EmployeeVacationPreferenceSet

  describe "get_latest_preferences/3" do
    test "Returns nil if no preferences" do
      assert nil ==
               EmployeeVacationPreferenceSet.get_latest_preferences(
                 "process_1",
                 "round_1",
                 "00001"
               )
    end

    test "Returns only set if only one" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      first_preference_set = %EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %EmployeeVacationPreference{
            start_date: ~D[2021-02-01],
            end_date: ~D[2021-02-07],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      Draft.Repo.insert!(first_preference_set)

      assert %EmployeeVacationPreferenceSet{
               process_id: "process_1",
               round_id: "vacation_1",
               employee_id: "00001",
               vacation_preferences: [
                 %EmployeeVacationPreference{
                   start_date: ~D[2021-02-01],
                   end_date: ~D[2021-02-07],
                   rank: 1,
                   interval_type: :week
                 }
               ]
             } =
               EmployeeVacationPreferenceSet.get_latest_preferences(
                 "process_1",
                 "vacation_1",
                 "00001"
               )
    end

    test "Returns latest set if two" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      first_preference_set = %EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %EmployeeVacationPreference{
            start_date: ~D[2021-02-01],
            end_date: ~D[2021-02-07],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      second_preference_set = %EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %EmployeeVacationPreference{
            start_date: ~D[2021-02-08],
            end_date: ~D[2021-02-14],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      Draft.Repo.insert!(first_preference_set)
      Draft.Repo.insert!(second_preference_set)

      assert %EmployeeVacationPreferenceSet{
               process_id: "process_1",
               round_id: "vacation_1",
               employee_id: "00001",
               vacation_preferences: [
                 %EmployeeVacationPreference{
                   start_date: ~D[2021-02-08],
                   end_date: ~D[2021-02-14],
                   rank: 1,
                   interval_type: :week
                 }
               ]
             } =
               EmployeeVacationPreferenceSet.get_latest_preferences(
                 "process_1",
                 "vacation_1",
                 "00001"
               )
    end

    test "Returns for correct process /round " do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_2",
          round_id: "vacation_2",
          division_id: "101"
        },
        %{
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      first_preference_set = %EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %EmployeeVacationPreference{
            start_date: ~D[2021-02-01],
            end_date: ~D[2021-02-07],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      second_preference_set = %EmployeeVacationPreferenceSet{
        process_id: "process_2",
        round_id: "vacation_2",
        employee_id: "00001",
        vacation_preferences: [
          %EmployeeVacationPreference{
            start_date: ~D[2021-02-08],
            end_date: ~D[2021-02-14],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      Draft.Repo.insert!(first_preference_set)
      Draft.Repo.insert!(second_preference_set)

      assert %EmployeeVacationPreferenceSet{
               process_id: "process_1",
               round_id: "vacation_1",
               employee_id: "00001",
               vacation_preferences: [
                 %EmployeeVacationPreference{
                   start_date: ~D[2021-02-01],
                   end_date: ~D[2021-02-07],
                   rank: 1,
                   interval_type: :week
                 }
               ]
             } =
               EmployeeVacationPreferenceSet.get_latest_preferences(
                 "process_1",
                 "vacation_1",
                 "00001"
               )
    end
  end

  describe "create/1" do
    test "Successfully creates preference set" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      assert {:ok,
              %EmployeeVacationPreferenceSet{
                process_id: "process_1",
                round_id: "vacation_1",
                employee_id: "00001",
                previous_preference_set_id: nil,
                vacation_preferences: [
                  %EmployeeVacationPreference{
                    start_date: ~D[2021-02-01],
                    end_date: ~D[2021-02-07],
                    rank: 1,
                    interval_type: :week
                  }
                ]
              }} =
               EmployeeVacationPreferenceSet.create(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00001",
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 1,
                     interval_type: :week
                   }
                 ]
               })
    end

    test "Creating ignores any given previous id " do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      assert {:ok,
              %EmployeeVacationPreferenceSet{
                process_id: "process_1",
                round_id: "vacation_1",
                employee_id: "00001",
                previous_preference_set_id: nil,
                vacation_preferences: [
                  %EmployeeVacationPreference{
                    start_date: ~D[2021-02-01],
                    end_date: ~D[2021-02-07],
                    rank: 1,
                    interval_type: :week
                  }
                ]
              }} =
               EmployeeVacationPreferenceSet.create(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00001",
                 previous_preference_set_id: 1234,
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 1,
                     interval_type: :week
                   }
                 ]
               })
    end
  end

  describe "update/1" do
    test "Has correct previous preference id when one is given" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
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
              interval_type: :week
            }
          ]
        })

      assert {:ok,
              %EmployeeVacationPreferenceSet{
                process_id: "process_1",
                round_id: "vacation_1",
                employee_id: "00001",
                previous_preference_set_id: ^previous_id,
                vacation_preferences: [
                  %EmployeeVacationPreference{
                    start_date: ~D[2021-02-08],
                    end_date: ~D[2021-02-14],
                    rank: 1,
                    interval_type: :week
                  }
                ]
              }} =
               EmployeeVacationPreferenceSet.update(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00001",
                 previous_preference_set_id: previous_id,
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-08],
                     end_date: ~D[2021-02-14],
                     rank: 1,
                     interval_type: :week
                   }
                 ]
               })
    end

    test "Cannot insert if invalid previous preference id" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
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
              interval_type: :week
            }
          ]
        })

      assert {:error, _} =
               EmployeeVacationPreferenceSet.update(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00001",
                 previous_preference_set_id: previous_id_different_employee,
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-08],
                     end_date: ~D[2021-02-14],
                     rank: 1,
                     interval_type: :week
                   }
                 ]
               })
    end

    test "Cannot insert preference set with two of the same vacation intervals" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      assert {:error, _} =
               EmployeeVacationPreferenceSet.create(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00001",
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 1,
                     interval_type: :week
                   },
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 2,
                     interval_type: :week
                   }
                 ]
               })
    end

    test "Cannot insert preference set for employee that doesn't exist" do
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
          round_rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          employee_count: 1,
          group_size: 10
        }
      )

      assert {:error, _} =
               EmployeeVacationPreferenceSet.create(%{
                 process_id: "process_1",
                 round_id: "vacation_1",
                 employee_id: "00002",
                 vacation_preferences: [
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 1,
                     interval_type: :week
                   },
                   %{
                     start_date: ~D[2021-02-01],
                     end_date: ~D[2021-02-07],
                     rank: 2,
                     interval_type: :week
                   }
                 ]
               })
    end
  end
end

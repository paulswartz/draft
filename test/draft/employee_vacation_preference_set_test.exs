defmodule Draft.EmployeeVacationPreferenceSetTest do
  @moduledoc false
  use Draft.DataCase
  alias Draft.EmployeeVacationPreferenceSet
  alias Draft.EmployeeVacationPreference

  import Draft.Factory

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
            preference_rank: 1,
            interval_type: "week"
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
                   preference_rank: 1,
                   interval_type: "week"
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
            preference_rank: 1,
            interval_type: "week"
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
            preference_rank: 1,
            interval_type: "week"
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
                   preference_rank: 1,
                   interval_type: "week"
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
            preference_rank: 1,
            interval_type: "week"
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
            preference_rank: 1,
            interval_type: "week"
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
                   preference_rank: 1,
                   interval_type: "week"
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
end

defmodule Draft.GenerateVacationDistribution.Days.Test do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.GenerateVacationDistribution
  alias Draft.VacationDistribution

  setup do
    insert_round_with_employees(
      %{
        round_id: "vacation_1",
        process_id: "process_1",
        rank: 1,
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

    insert!(:division_vacation_day_quota, %{
      date: ~D[2021-04-03],
      quota: 1
    })

    insert!(:division_vacation_day_quota, %{
      date: ~D[2021-04-02],
      quota: 1
    })

    insert!(:division_vacation_day_quota, %{
      date: ~D[2021-04-01],
      quota: 1
    })

    {:ok,
     round: Repo.one!(from(r in Draft.BidRound)),
     employee_ranking: Repo.one!(from(e in Draft.EmployeeRanking))}
  end

  describe "distribute/4" do
    test "Operator whose anniversary date has passed can take full amount of vacation time available",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          2,
          [],
          %{
            anniversary_date: ~D[2021-03-01],
            anniversary_weeks: 0,
            anniversary_days: 2
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator who has no anniversary date can take full amount of vacation time available",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          2,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date on start date of rating period can take full amount of vacation ",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          2,
          [],
          %{
            anniversary_date: ~D[2021-04-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date in the middle of rating period only assigned vacation earned prior to anniversary",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          2,
          [],
          %{
            anniversary_date: ~D[2021-04-02],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date after rating period only assigned vacation available before anniversary date",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          2,
          [],
          %{
            anniversary_date: ~D[2021-06-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :day,
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with no vacation time remaining and anniversary that has passed is not distributed any time",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          0,
          [],
          %{
            anniversary_date: ~D[2021-03-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [] = vacation_assignments
    end

    test "Operator with no vacation time remaining and anniversary that is upcoming is not distributed any time",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          0,
          [],
          %{
            anniversary_date: ~D[2021-06-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [] = vacation_assignments
    end

    test "Operator with vacation day preferences is assigned preferred day when it is still available",
         state do
      preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-01],
            end_date: ~D[2021-04-01],
            rank: 1,
            interval_type: :day
          }
        ]
      }

      Draft.Repo.insert!(preferred_vacation)

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with vacation day preferences is assigned only one day if only one preference is still available",
         state do
      preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-01],
            end_date: ~D[2021-04-01],
            rank: 1,
            interval_type: :day
          },
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-21],
            end_date: ~D[2021-04-21],
            rank: 2,
            interval_type: :day
          }
        ]
      }

      Draft.Repo.insert!(preferred_vacation)

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with more vacation preferences than their quota is only assigned as many days as is allowed by their quota",
         state do
      preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-01],
            end_date: ~D[2021-04-01],
            rank: 1,
            interval_type: :day
          },
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-02],
            end_date: ~D[2021-04-02],
            rank: 2,
            interval_type: :day
          }
        ]
      }

      Draft.Repo.insert!(preferred_vacation)

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with vacation day preferences is not assigned their preferred day when it is not available",
         state do
      preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-22],
            end_date: ~D[2021-04-22],
            rank: 1,
            interval_type: :day
          }
        ]
      }

      Draft.Repo.insert!(preferred_vacation)

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [] = vacation_assignments
    end

    test "Operator with vacation day preferences is not assigned that day when it has been taken by someone earlier in the same run",
         state do
      group_number = 1234

      run_id =
        Draft.VacationDistributionRun.insert(%Draft.BidGroup{
          process_id: "process_1",
          round_id: "vacation_1",
          group_number: group_number
        })

      Draft.VacationDistribution.add_distributions_to_run(run_id, [
        %VacationDistribution{
          employee_id: "00002",
          interval_type: :day,
          start_date: ~D[2021-04-01],
          end_date: ~D[2021-04-01]
        }
      ])

      preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
        process_id: "process_1",
        round_id: "vacation_1",
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-04-01],
            end_date: ~D[2021-04-01],
            rank: 1,
            interval_type: :day
          }
        ]
      }

      Draft.Repo.insert!(preferred_vacation)

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          run_id,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [] = vacation_assignments
    end

    test "Operator is not assigned vacation day they've already selected", state do
      insert!(:employee_vacation_selection, %{
        vacation_interval_type: :day,
        start_date: ~D[2021-04-03],
        end_date: ~D[2021-04-03],
        status: :assigned
      })

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1234,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator can be re-assigned vacation day that has been previously cancelled", state do
      insert!(:employee_vacation_selection, %{
        vacation_interval_type: :day,
        start_date: ~D[2021-04-03],
        end_date: ~D[2021-04-03],
        status: :cancelled
      })

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1234,
          state.round,
          state.employee_ranking,
          1,
          [],
          nil
        )

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-03],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end
  end
end

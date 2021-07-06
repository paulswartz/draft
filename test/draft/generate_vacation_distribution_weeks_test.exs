defmodule Draft.GenerateVacationDistribution.Weeks.Test do
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

    insert!(:division_vacation_week_quota, %{
      start_date: ~D[2021-04-01],
      end_date: ~D[2021-04-07],
      quota: 1
    })

    insert!(:division_vacation_week_quota, %{
      start_date: ~D[2021-04-08],
      end_date: ~D[2021-04-14],
      quota: 1
    })

    insert!(:division_vacation_week_quota, %{
      start_date: ~D[2021-04-15],
      end_date: ~D[2021-04-21],
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
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          2,
          %{
            anniversary_date: ~D[2021-03-01],
            anniversary_weeks: 2,
            anniversary_days: 0
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator who has no anniversary date can take full amount of vacation time available",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          2,
          nil
        )

      assert [
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date on start date of rating period can take full amount of vacation ",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          2,
          %{
            anniversary_date: ~D[2021-04-01],
            anniversary_weeks: 1,
            anniversary_days: 0
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date in the middle of rating period only assigned vacation up to their anniversary date",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          2,
          %{
            anniversary_date: ~D[2021-04-15],
            anniversary_weeks: 1,
            anniversary_days: 0
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date after rating period only assigned vacation available before anniversary date",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          2,
          %{
            anniversary_date: ~D[2021-06-01],
            anniversary_weeks: 1,
            anniversary_days: 0
          }
        )

      assert [
               %VacationDistribution{
                 interval_type: :week,
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with no vacation weeks remaining and anniversary that has passed is not distributed any time",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          0,
          %{
            anniversary_date: ~D[2021-03-01],
            anniversary_weeks: 1,
            anniversary_days: 0
          }
        )

      assert [] = vacation_assignments
    end

    test "Operator with no vacation weeks remaining and anniversary that is upcoming is not distributed any time",
         state do
      vacation_assignments =
        GenerateVacationDistribution.Weeks.generate(
          state.round,
          state.employee_ranking,
          0,
          %{
            anniversary_date: ~D[2021-06-01],
            anniversary_weeks: 1,
            anniversary_days: 0
          }
        )

      assert [] = vacation_assignments
    end
  end

  test "Operator with vacation week preferences is assigned preferred week when it is still available",
       state do
    preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
      process_id: "process_1",
      round_id: "vacation_1",
      employee_id: "00001",
      vacation_preferences: [
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-08],
          end_date: ~D[2021-04-14],
          rank: 1,
          interval_type: :week
        }
      ]
    }

    Draft.Repo.insert!(preferred_vacation)

    vacation_assignments =
      GenerateVacationDistribution.Weeks.generate(
        state.round,
        state.employee_ranking,
        1,
        nil
      )

    assert [
             %VacationDistribution{
               start_date: ~D[2021-04-08],
               end_date: ~D[2021-04-14],
               employee_id: "00001"
             }
           ] = vacation_assignments
  end

  test "Operator with vacation week preferences is assigned only one week if only one preference is still available",
       state do
    preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
      process_id: "process_1",
      round_id: "vacation_1",
      employee_id: "00001",
      vacation_preferences: [
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-08],
          end_date: ~D[2021-04-14],
          rank: 1,
          interval_type: :week
        },
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-21],
          end_date: ~D[2021-04-28],
          rank: 2,
          interval_type: :week
        }
      ]
    }

    Draft.Repo.insert!(preferred_vacation)

    vacation_assignments =
      GenerateVacationDistribution.Weeks.generate(
        state.round,
        state.employee_ranking,
        1,
        nil
      )

    assert [
             %VacationDistribution{
               start_date: ~D[2021-04-08],
               end_date: ~D[2021-04-14],
               employee_id: "00001"
             }
           ] = vacation_assignments
  end

  test "Operator with more vacation preferences than their quota is only assigned as many weeks as is allowed by their quota",
       state do
    preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
      process_id: "process_1",
      round_id: "vacation_1",
      employee_id: "00001",
      vacation_preferences: [
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-08],
          end_date: ~D[2021-04-14],
          rank: 1,
          interval_type: :week
        },
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-07],
          end_date: ~D[2021-04-01],
          rank: 2,
          interval_type: :week
        }
      ]
    }

    Draft.Repo.insert!(preferred_vacation)

    vacation_assignments =
      GenerateVacationDistribution.Weeks.generate(
        state.round,
        state.employee_ranking,
        1,
        nil
      )

    assert [
             %VacationDistribution{
               start_date: ~D[2021-04-08],
               end_date: ~D[2021-04-14],
               employee_id: "00001"
             }
           ] = vacation_assignments
  end

  test "Operator with vacation week preferences is not assigned their preferred week when it is not available",
       state do
    preferred_vacation = %Draft.EmployeeVacationPreferenceSet{
      process_id: "process_1",
      round_id: "vacation_1",
      employee_id: "00001",
      vacation_preferences: [
        %Draft.EmployeeVacationPreference{
          start_date: ~D[2021-04-22],
          end_date: ~D[2021-04-28],
          rank: 1,
          interval_type: :week
        }
      ]
    }

    Draft.Repo.insert!(preferred_vacation)

    vacation_assignments =
      GenerateVacationDistribution.Weeks.generate(
        state.round,
        state.employee_ranking,
        1,
        nil
      )

    assert [] = vacation_assignments
  end
end

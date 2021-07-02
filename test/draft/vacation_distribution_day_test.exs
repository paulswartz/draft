defmodule Draft.VacationDistribution.Day.Test do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationAssignment
  alias Draft.VacationDistribution

  setup do
    insert_round_with_employees(
      %{
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
      date: ~D[2021-04-01],
      quota: 1
    })

    insert!(:division_vacation_day_quota, %{
      date: ~D[2021-04-02],
      quota: 1
    })

    insert!(:division_vacation_day_quota, %{
      date: ~D[2021-04-03],
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
        VacationDistribution.Day.distribute(
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
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator who has no anniversary date can take full amount of vacation time available",
         state do
      vacation_assignments =
        VacationDistribution.Day.distribute(
          state.round,
          state.employee_ranking,
          2,
          [],
          nil
        )

      assert [
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date on start date of rating period can take full amount of vacation ",
         state do
      vacation_assignments =
        VacationDistribution.Day.distribute(
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
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-02],
                 end_date: ~D[2021-04-02],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date in the middle of rating period only assigned vacation up to their anniversary date",
         state do
      vacation_assignments =
        VacationDistribution.Day.distribute(
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
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with anniversary date after rating period only assigned vacation available before anniversary date",
         state do
      vacation_assignments =
        VacationDistribution.Day.distribute(
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
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with no vacation time remaining and anniversary that has passed is not distributed any time",
         state do
      vacation_assignments =
        VacationDistribution.Day.distribute(
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
        VacationDistribution.Day.distribute(
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
  end
end

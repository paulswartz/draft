defmodule Draft.VacationWeekDistributionTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationAssignment
  alias Draft.VacationWeekDistribution

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

    {:ok,
     round: Repo.one!(from(r in Draft.BidRound)),
     employee_ranking: Repo.one!(from(e in Draft.EmployeeRanking))}
  end

  describe "distribute_weeks_balance/4" do
    test "Operator whose anniversary date has passed can take full amount of vacation time available",
         state do
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

      vacation_assignments =
        VacationWeekDistribution.distribute_weeks_balance(
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
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    # add tests:
    # - no anniversary date
    # - anniversary date on first day of rating period
    # - anniversary date on last day of rating period
    # - anniversary date in middle of rating period
    # - anniversary date after rating period
  end
end

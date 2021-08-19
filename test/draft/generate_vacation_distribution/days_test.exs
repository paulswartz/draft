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
      },
      %{type: :vacation, type_allowed: :day}
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

    # Insert default preferences for operator, which can be overridden in particular test cases
    insert_vacation_preferences(
      "vacation_1",
      "process_1",
      %{"00001" => [~D[2021-04-03], ~D[2021-04-02], ~D[2021-04-01]]},
      :day
    )

    {:ok,
     round: Repo.one!(from(r in Draft.BidRound)),
     employee_ranking: Repo.one!(from(e in Draft.EmployeeRanking))}
  end

  describe "distribute/4" do
    test "Operator whose anniversary date has passed can take full amount of vacation time available",
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          2,
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
         %{round: round, employee_ranking: employee_ranking} do
      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-03], ~D[2021-04-02], ~D[2021-04-01]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          2,
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
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          2,
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
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          2,
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
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          2,
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
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          0,
          %{
            anniversary_date: ~D[2021-03-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [] = vacation_assignments
    end

    test "Operator with no vacation time remaining and anniversary that is upcoming is not distributed any time",
         %{round: round, employee_ranking: employee_ranking} do
      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          0,
          %{
            anniversary_date: ~D[2021-06-01],
            anniversary_weeks: 0,
            anniversary_days: 1
          }
        )

      assert [] = vacation_assignments
    end

    test "Operator with vacation day preferences is assigned preferred day when it is still available",
         %{round: round, employee_ranking: employee_ranking} do
      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-01]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          1,
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
         %{round: round, employee_ranking: employee_ranking} do
      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-22], ~D[2021-04-01]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          1,
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
         %{round: round, employee_ranking: employee_ranking} do
      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-01], ~D[2021-04-02]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          1,
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
         %{round: round, employee_ranking: employee_ranking} do
      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-22]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1,
          round,
          employee_ranking,
          1,
          nil
        )

      assert [] = vacation_assignments
    end

    test "Operator with vacation day preferences is not assigned that day when it has been taken by someone earlier in the same run",
         %{round: round, employee_ranking: employee_ranking} do
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

      insert_vacation_preferences(
        round.round_id,
        round.process_id,
        %{"00001" => [~D[2021-04-01]]},
        :day
      )

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          run_id,
          round,
          employee_ranking,
          1,
          nil
        )

      assert [] = vacation_assignments
    end

    test "Operator is not assigned vacation day they've already selected", %{
      round: round,
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_selection, %{
        vacation_interval_type: :day,
        start_date: ~D[2021-04-03],
        end_date: ~D[2021-04-03],
        status: :assigned
      })

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1234,
          round,
          employee_ranking,
          1,
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

    test "Operator can be re-assigned vacation day that has been previously cancelled", %{
      round: round,
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_selection, %{
        vacation_interval_type: :day,
        start_date: ~D[2021-04-03],
        end_date: ~D[2021-04-03],
        status: :cancelled
      })

      vacation_assignments =
        GenerateVacationDistribution.Days.generate(
          1234,
          round,
          employee_ranking,
          1,
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

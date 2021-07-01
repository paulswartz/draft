defmodule Draft.BasicVacationDistributionTest do
  use ExUnit.Case, async: true
  use Draft.DataCase
  import Draft.Factory
  alias Draft.BasicVacationDistributionRunner
  alias Draft.VacationDistribution

  describe "run/1" do
    test "Operator is not assigned vacation week with quota of 0" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 0
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-27]
             end) == []

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               vacation_assignments
    end

    test "Operator is not assigned vacation day with quota of 0" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 480
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 0})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-21]
             end) == []

      assert [%VacationDistribution{start_date: ~D[2021-03-22], end_date: ~D[2021-03-22]}] =
               vacation_assignments
    end

    test "Operator with no vacation time is not assigned vacation" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 0,
        maximum_minutes: 0
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert vacation_assignments == []
    end

    test "Operator with quota of two weeks is assigned two different weeks" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4830
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-03-28],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with quota of two days is assigned two different days" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 2})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-21],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-03-22],
                 end_date: ~D[2021-03-22],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Second operator is not given vacation day where quota has been filled by previous operator" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 2,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00002",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 480
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-23], quota: 1})

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-23],
                 end_date: ~D[2021-03-23],
                 employee_id: "00002"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00002")
    end

    test "Second operator is not given vacation week where quota has been filled by previous operator" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 2,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00002",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-04],
        end_date: ~D[2021-04-10],
        quota: 1
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-04],
                 end_date: ~D[2021-04-10],
                 employee_id: "00002"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00002")
    end

    test "Operator is given first available week that doesn't conflict with the week they've already selected" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-28],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available week that doesn't conflict with the day they've already selected" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-23],
        end_date: ~D[2021-03-23],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-28],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available day that doesn't conflict with the day they've already selected" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-21],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-22],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-21],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-22],
                 end_date: ~D[2021-03-22],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available day that doesn't conflict with the week they've already selected" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-22],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-04-01],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator whose anniversary date has passed can take full amount of vacation time available" do
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

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        available_after_date: ~D[2021-03-15],
        available_after_weekly_quota: 1,
        maximum_minutes: 4800
      })

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

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is during the round is only assigned vacation before anniversary date" do
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

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 3,
        dated_quota: 0,
        available_after_date: ~D[2021-04-15],
        available_after_weekly_quota: 1,
        available_after_dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-22],
        end_date: ~D[2021-04-28],
        quota: 1
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is after the round is only assigned vacation before anniversary date" do
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

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 3,
        dated_quota: 0,
        available_after_date: ~D[2021-06-15],
        available_after_weekly_quota: 1,
        available_after_dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-22],
        end_date: ~D[2021-04-28],
        quota: 1
      })

      vacation_assignments = BasicVacationDistributionRunner.run()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-07],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end
  end

  defp get_assignments_for_employee(assignments, employee_id) do
    Enum.filter(assignments, fn x ->
      x.employee_id == employee_id
    end)
  end
end

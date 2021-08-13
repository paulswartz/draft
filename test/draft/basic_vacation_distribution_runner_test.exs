defmodule Draft.BasicVacationDistributionRunnerTest do
  use ExUnit.Case, async: true
  use Draft.DataCase
  import Draft.Factory
  alias Draft.BasicVacationDistributionRunner
  alias Draft.VacationDistribution

  describe "run_all_rounds/1" do
    test "Operator is not assigned vacation week with quota of 0" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 0
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-27]
             end) == []

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               vacation_assignments
    end

    test "Distribution runner saves to DB" do
      setup_pick(%{interval_type: :week, employee_count: 1})

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

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-27]
             end) == []

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               vacation_assignments

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               Draft.Repo.all(VacationDistribution)
    end

    test "Operator is not assigned vacation day with quota of 0" do
      setup_pick(%{interval_type: :day, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 480
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 0})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-21]
             end) == []

      assert [%VacationDistribution{start_date: ~D[2021-03-22], end_date: ~D[2021-03-22]}] =
               vacation_assignments
    end

    test "Operator with no vacation time is not assigned vacation" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 0,
        maximum_minutes: 0
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert vacation_assignments == []
    end

    test "Operator with quota of two weeks is assigned two different weeks" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4830
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-28],
                 end_date: ~D[2021-04-03],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator with quota of two days is assigned two different days" do
      setup_pick(%{interval_type: :day, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 2})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-22],
                 end_date: ~D[2021-03-22],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-21],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Second operator is not given vacation day where quota has been filled by previous operator" do
      setup_pick(%{interval_type: :day, employee_count: 2})

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

      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-23], quota: 1})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})
      insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-21],
                 employee_id: "00002"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00002")
    end

    test "Second operator is not given vacation week where quota has been filled by previous operator" do
      setup_pick(%{interval_type: :week, employee_count: 2})

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
        start_date: ~D[2021-04-04],
        end_date: ~D[2021-04-10],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00002"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00002")
    end

    test "Operator is given first available week that doesn't conflict with the week they've already selected" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        employee_id: "00001"
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available week that doesn't conflict with the day they've already selected" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-01],
        employee_id: "00001"
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available day that doesn't conflict with the day they've already selected" do
      setup_pick(%{interval_type: :day, employee_count: 1})

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
        date: ~D[2021-03-21],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-22],
        end_date: ~D[2021-03-22],
        employee_id: "00001"
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-21],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator is given first available day that doesn't conflict with the week they've already selected" do
      setup_pick(%{interval_type: :day, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-04-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-22],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        employee_id: "00001"
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-22],
                 end_date: ~D[2021-03-22],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator whose anniversary date has passed can take full amount of vacation time available" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        available_after_date: ~D[2021-03-15],
        available_after_weekly_quota: 1,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-15],
                 end_date: ~D[2021-04-21],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-04-08],
                 end_date: ~D[2021-04-14],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is during the round is only assigned vacation time earned before anniversary week" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        available_after_date: ~D[2021-04-15],
        available_after_weekly_quota: 1,
        available_after_dated_quota: 0,
        maximum_minutes: 4800
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-22],
        end_date: ~D[2021-04-28],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-22],
                 end_date: ~D[2021-04-28],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is after the round is only assigned vacation before anniversary date" do
      setup_pick(%{interval_type: :week, employee_count: 1})

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
        start_date: ~D[2021-04-22],
        end_date: ~D[2021-04-28],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-22],
                 end_date: ~D[2021-04-28],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end
  end

  describe "distribute_vacation_to_group/1" do
    test "Returns error if group is not found" do
      assert {:error, _error} =
               BasicVacationDistributionRunner.distribute_vacation_to_group(
                 %{
                   round_id: "missing_round",
                   group_number: 1,
                   process_id: "missing_process"
                 },
                 :week
               )
    end

    test "Returns successfully if group is found" do
      setup_pick(%{interval_type: :week, employee_count: 1})

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-01],
                  end_date: ~D[2021-04-07],
                  employee_id: "00001"
                }
              ]} =
               BasicVacationDistributionRunner.distribute_vacation_to_group(
                 %{
                   round_id: "round_1",
                   group_number: 1,
                   process_id: "process_1"
                 },
                 :week
               )
    end
  end

  defp get_assignments_for_employee(assignments, employee_id) do
    Enum.filter(assignments, fn x ->
      x.employee_id == employee_id
    end)
  end

  defp setup_pick(%{interval_type: interval_type, employee_count: employee_count}) do
    insert_round_with_employees(
      %{
        rank: 1,
        round_opening_date: ~D[2021-01-01],
        round_id: "round_1",
        process_id: "process_1",
        round_closing_date: ~D[2021-02-01],
        rating_period_start_date: ~D[2021-03-15],
        rating_period_end_date: ~D[2021-05-01]
      },
      %{
        employee_count: employee_count,
        group_size: 10
      },
      %{type: :vacation, type_allowed: interval_type}
    )
  end
end

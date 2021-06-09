defmodule Draft.BasicVacationDistributionTest do
  use ExUnit.Case, async: true
  use Draft.DataCase
  alias Draft.BasicVacationDistribution
  alias Draft.EmployeeVacationAssignment

  describe "basic_vacation_distribution/1" do
    test "Operator is not assigned vacation week with quota of 0" do
      insert_round_with_employees(%{
        round_rank: 1,
        round_opening_date: ~D[2021-02-01],
        round_closing_date: ~D[2021-03-01],
        employee_count: 1,
        group_size: 10
      })

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 0
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-27]
             end) == []

      assert [%EmployeeVacationAssignment{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 480
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 0})
      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert Enum.filter(vacation_assignments, fn x ->
               x.start_date == ~D[2021-03-21] and x.end_date == ~D[2021-03-21]
             end) == []

      assert [%EmployeeVacationAssignment{start_date: ~D[2021-03-22], end_date: ~D[2021-03-22]}] =
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 0,
        maximum_minutes: 0
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4830
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 2
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-27],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 2})
      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-03-21],
                 end_date: ~D[2021-03-21],
                 employee_id: "00001"
               },
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00002",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 480
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-21], quota: 1})
      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-22], quota: 1})
      Draft.Factory.insert!(:division_vacation_day_quota, %{date: ~D[2021-03-23], quota: 1})

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00002",
        weekly_quota: 1,
        dated_quota: 0,
        maximum_minutes: 2400
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-04],
        end_date: ~D[2021-04-10],
        quota: 1
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      Draft.Factory.insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        dated_quota: 0,
        maximum_minutes: 4800
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-03-28],
        end_date: ~D[2021-04-03],
        quota: 1
      })

      Draft.Factory.insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-23],
        end_date: ~D[2021-03-23],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-21],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-22],
        quota: 1
      })

      Draft.Factory.insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-21],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
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

      Draft.Factory.insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 2,
        maximum_minutes: 1000
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{
        date: ~D[2021-03-22],
        quota: 1
      })

      Draft.Factory.insert!(:division_vacation_day_quota, %{
        date: ~D[2021-04-01],
        quota: 1
      })

      Draft.Factory.insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        employee_id: "00001"
      })

      vacation_assignments = BasicVacationDistribution.basic_vacation_distribution()

      assert [
               %EmployeeVacationAssignment{
                 start_date: ~D[2021-04-01],
                 end_date: ~D[2021-04-01],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end
  end

  defp get_assignments_for_employee(assignments, employee_id) do
    Enum.filter(assignments, fn x ->
      x.employee_id == employee_id
    end)
  end

  defp insert_round_with_employees(%{
         round_rank: round_rank,
         round_opening_date: round_opening_date,
         round_closing_date: round_closing_date,
         employee_count: employee_count,
         group_size: group_size
       }) do
    Draft.Factory.insert!(:round, %{
      round_opening_date: round_opening_date,
      round_closing_date: round_closing_date,
      rank: round_rank
    })

    grouped_employees = Enum.with_index(Enum.chunk_every(1..employee_count, group_size), 1)

    Enum.each(grouped_employees, fn {group, index} ->
      Draft.Factory.insert!(:group, %{group_number: index})

      Enum.each(Enum.with_index(group, 1), fn {emp_id, emp_rank} ->
        Draft.Factory.insert!(
          :employee_ranking,
          %{
            group_number: index,
            rank: emp_rank,
            employee_id: String.pad_leading(Integer.to_string(emp_id), 5, "0")
          }
        )
      end)
    end)
  end
end

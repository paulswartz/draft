defmodule Draft.BasicVacationDistributionRunnerTest do
  use ExUnit.Case, async: true
  use Draft.DataCase
  import Draft.Factory
  alias Draft.BasicVacationDistributionRunner
  alias Draft.VacationDistribution

  @default_week_preferences [
    ~D[2021-04-25],
    ~D[2021-04-18],
    ~D[2021-04-11],
    ~D[2021-04-04],
    ~D[2021-03-28],
    ~D[2021-03-21],
    ~D[2021-03-14],
    ~D[2021-03-07]
  ]

  @default_day_preferences [~D[2021-03-23], ~D[2021-03-22], ~D[2021-03-21], ~D[2021-03-20]]

  describe "run_all_rounds/1" do
    test "Operator is not assigned vacation week with quota of 0" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 1, ~D[2021-03-21] => 0},
        %{"00001" => 1},
        %{},
        %{"00001" => @default_week_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               vacation_assignments
    end

    test "Distribution runner saves to DB" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 1, ~D[2021-03-21] => 0},
        %{"00001" => 1},
        %{},
        %{"00001" => @default_week_preferences}
      )

      BasicVacationDistributionRunner.run_all_rounds()

      assert [%VacationDistribution{start_date: ~D[2021-03-28], end_date: ~D[2021-04-03]}] =
               Draft.Repo.all(VacationDistribution)
    end

    test "Operator is not assigned vacation day with quota of 0" do
      insert_round_with_employees_and_vacation(
        :day,
        %{~D[2021-03-22] => 1, ~D[2021-03-21] => 0},
        %{"00001" => 1},
        %{},
        %{"00001" => @default_day_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [%VacationDistribution{start_date: ~D[2021-03-22], end_date: ~D[2021-03-22]}] =
               vacation_assignments
    end

    test "Operator with no vacation time is not assigned vacation" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 0},
        %{},
        %{"00001" => @default_week_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert vacation_assignments == []
    end

    test "Operator with quota of two weeks is assigned two different weeks" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 2, ~D[2021-03-21] => 1},
        %{"00001" => 2},
        %{},
        %{"00001" => @default_week_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :day,
        %{~D[2021-03-22] => 2, ~D[2021-03-21] => 1},
        %{"00001" => 2},
        %{},
        %{"00001" => @default_day_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :day,
        %{~D[2021-03-23] => 1, ~D[2021-03-22] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 2, "00002" => 1},
        %{},
        %{"00001" => @default_day_preferences, "00002" => @default_day_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-04-04] => 1, ~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 2, "00002" => 1},
        %{},
        %{"00001" => @default_week_preferences, "00002" => @default_day_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 2},
        %{"00001" => [~D[2021-03-28]]},
        %{"00001" => @default_week_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-03-28] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 2},
        %{},
        %{"00001" => @default_week_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :day,
        %{~D[2021-03-22] => 1, ~D[2021-03-21] => 1},
        %{"00001" => 2},
        %{"00001" => [~D[2021-03-22]]},
        %{"00001" => @default_day_preferences}
      )

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
      insert_round_with_employees_and_vacation(
        :day,
        %{~D[2021-03-22] => 1, ~D[2021-03-21] => 1, ~D[2021-03-20] => 1},
        %{"00001" => 2},
        %{},
        %{"00001" => @default_day_preferences}
      )

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-03-21],
        end_date: ~D[2021-03-27],
        employee_id: "00001"
      })

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-03-20],
                 end_date: ~D[2021-03-20],
                 employee_id: "00001"
               }
             ] = get_assignments_for_employee(vacation_assignments, "00001")
    end

    test "Operator whose anniversary date has passed can take full amount of vacation time available" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-04-11] => 1, ~D[2021-04-04] => 1},
        %{"00001" => %{total_quota: 2, anniversary_date: ~D[2021-03-15], anniversary_quota: 1}},
        %{},
        %{"00001" => @default_week_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-11],
                 end_date: ~D[2021-04-17],
                 employee_id: "00001"
               },
               %VacationDistribution{
                 start_date: ~D[2021-04-04],
                 end_date: ~D[2021-04-10],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is during the round is only assigned vacation time earned before anniversary week" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-04-18] => 1, ~D[2021-04-11] => 1, ~D[2021-04-04] => 1},
        %{"00001" => %{total_quota: 2, anniversary_date: ~D[2021-04-15], anniversary_quota: 1}},
        %{},
        %{"00001" => @default_week_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-18],
                 end_date: ~D[2021-04-24],
                 employee_id: "00001"
               }
             ] = vacation_assignments
    end

    test "Operator whose anniversary date is after the round is only assigned vacation before anniversary date" do
      insert_round_with_employees_and_vacation(
        :week,
        %{~D[2021-04-18] => 1, ~D[2021-04-11] => 1, ~D[2021-04-04] => 1},
        %{"00001" => %{total_quota: 2, anniversary_date: ~D[2021-06-15], anniversary_quota: 1}},
        %{},
        %{"00001" => @default_week_preferences}
      )

      {:ok, vacation_assignments} = BasicVacationDistributionRunner.run_all_rounds()

      assert [
               %VacationDistribution{
                 start_date: ~D[2021-04-18],
                 end_date: ~D[2021-04-24],
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
      group =
        insert_round_with_employees_and_vacation(
          :week,
          %{~D[2021-04-04] => 1},
          %{"00001" => 1},
          %{},
          %{"00001" => @default_week_preferences}
        )

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-04],
                  end_date: ~D[2021-04-10],
                  employee_id: "00001"
                }
              ]} =
               BasicVacationDistributionRunner.distribute_vacation_to_group(
                 group,
                 :week
               )
    end
  end

  defp get_assignments_for_employee(assignments, employee_id) do
    Enum.filter(assignments, fn x ->
      x.employee_id == employee_id
    end)
  end
end

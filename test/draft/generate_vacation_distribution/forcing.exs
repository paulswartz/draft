defmodule Draft.GenerateVacationDistribution.Weeks.Test do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.GenerateVacationDistribution
  alias Draft.VacationDistribution

  describe "distribute_to_group/4" do
    test "One operator being forced gets the latest available weeks" do
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
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_assignments =
        GenerateVacationDistribution.Weeks.distribute_vacation_to_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              %{~D[2021-04-08] => MapSet.new(["00001"]), ~D[2021-04-15] => MapSet.new(["00001"])}} ==
               vacation_assignments
    end

    test "Two operators being forced can take the same day when quota is 2" do
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
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 2
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

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00002",
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_assignments =
        GenerateVacationDistribution.Weeks.distribute_vacation_to_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              %{
                ~D[2021-04-01] => MapSet.new(["00002"]),
                ~D[2021-04-08] => MapSet.new(["00001"]),
                ~D[2021-04-15] => MapSet.new(["00001", "00002"])
              }} == vacation_assignments
    end

    test "Assigns first operator the second best week in order to ensure valid forcing" do
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
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 2
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 1,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00002",
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_assignments =
        GenerateVacationDistribution.Weeks.distribute_vacation_to_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              %{
                ~D[2021-04-08] => MapSet.new(["00001", "00002"]),
                ~D[2021-04-15] => MapSet.new(["00002"])
              }} == vacation_assignments
    end
  end
end

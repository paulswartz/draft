defmodule Draft.VacationDistributionWorkerTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.VacationDistribution
  alias Draft.VacationDistributionWorker

  describe "perform/1" do
    test "Successfully distributes vacation weeks" do
      insert_round_with_employees(
        %{
          rank: 1,
          round_id: "round_1",
          process_id: "process_1",
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          rating_period_start_date: ~D[2021-04-01],
          rating_period_end_date: ~D[2021-05-01]
        },
        %{
          employee_count: 1,
          group_size: 10
        },
        %{type: :vacation, type_allowed: :week}
      )

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
                  interval_type: :week,
                  employee_id: "00001"
                }
              ]} =
               VacationDistributionWorker.perform(%Oban.Job{
                 args: %{
                   "round_id" => "round_1",
                   "process_id" => "process_1",
                   "group_number" => 1
                 }
               })
    end

    test "Successfully distributes vacation days" do
      insert_round_with_employees(
        %{
          rank: 1,
          round_id: "round_1",
          process_id: "process_1",
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

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 0,
        dated_quota: 1,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_day_quota, %{
        date: ~D[2021-04-01],
        quota: 1
      })

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-01],
                  end_date: ~D[2021-04-01],
                  interval_type: :day,
                  employee_id: "00001"
                }
              ]} =
               VacationDistributionWorker.perform(%Oban.Job{
                 args: %{
                   "round_id" => "round_1",
                   "process_id" => "process_1",
                   "group_number" => 1
                 }
               })
    end

    test "Returns error when unsuccessful distribution" do
      assert {:error, _errors} =
               VacationDistributionWorker.perform(%Oban.Job{
                 args: %{
                   "round_id" => "missing round",
                   "process_id" => "missing process",
                   "group_number" => 1
                 }
               })
    end
  end
end

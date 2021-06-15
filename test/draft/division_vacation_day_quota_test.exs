defmodule Draft.DivisionVacationDayQuotaTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory
  alias Draft.DivisionVacationDayQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_dated =
        DivisionVacationDayQuota.from_parts([
          "125",
          "FTVacQuota",
          "02/11/2021",
          "5"
        ])

      assert %DivisionVacationDayQuota{
               division_id: "125",
               employee_selection_set: "FTVacQuota",
               date: ~D[2021-02-11],
               quota: 5
             } = div_quota_dated
    end
  end

  describe "all_available_days/3" do
    test "Returns only days within the pick date for the given round" do
      Draft.Factory.insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_1",
          round_id: "vacation_1",
          division_id: "101"
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-02-02],
        quota: 0
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-01-29],
        quota: 2
      })

      available_days =
        DivisionVacationDayQuota.all_available_days(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationDayQuota{date: ~D[2021-02-01]}] = available_days
    end

    test "Returns only days within the appropriate division" do
      Draft.Factory.insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_1",
          round_id: "vacation_1",
          division_id: "101"
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "102",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-02-02],
        quota: 1
      })

      available_days =
        DivisionVacationDayQuota.all_available_days(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationDayQuota{date: ~D[2021-02-01]}] = available_days
    end

    test "Returns only days within the appropriate employee set" do
      Draft.Factory.insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-02-01],
          rating_period_end_date: ~D[2021-03-01],
          process_id: "process_1",
          round_id: "vacation_1",
          division_id: "101"
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        employee_selection_set: "PTVacQuota",
        date: ~D[2021-02-02],
        quota: 1
      })

      available_days =
        DivisionVacationDayQuota.all_available_days(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationDayQuota{date: ~D[2021-02-01]}] = available_days
    end
  end
end

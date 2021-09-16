defmodule Draft.EmployeeVacationPickOverviewTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationPickOverview

  describe "open_round/1" do
    test "Returns pick overview for present employee when operator will be forced" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees(
          %{
            round_opening_date: Date.add(Date.utc_today(), -5),
            round_closing_date: Date.add(Date.utc_today(), 5)
          },
          %{group_size: 1, employee_count: 1},
          %{
            rating_period_start_date: Date.add(Date.utc_today(), 10),
            rating_period_end_date: Date.add(Date.utc_today(), 50)
          }
        )

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: Date.add(Date.utc_today(), 30),
        end_date: Date.add(Date.utc_today(), 36),
        quota: 1
      })

      assert %EmployeeVacationPickOverview{
               employee_id: "00001",
               rank: 1,
               job_class: "000100",
               round_id: ^round_id,
               process_id: ^process_id,
               is_below_point_of_forcing: true
             } = EmployeeVacationPickOverview.open_round("00001")
    end

    test "Returns pick overview for present employee when not yet known if operator will be forced " do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees(
          %{
            round_opening_date: Date.add(Date.utc_today(), -5),
            round_closing_date: Date.add(Date.utc_today(), 5)
          },
          %{group_size: 1, employee_count: 2},
          %{
            rating_period_start_date: Date.add(Date.utc_today(), 10),
            rating_period_end_date: Date.add(Date.utc_today(), 50)
          }
        )

      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 1,
        maximum_minutes: 2400
      })

      insert!(:employee_vacation_quota, %{
        employee_id: "00002",
        weekly_quota: 1,
        maximum_minutes: 2400
      })

      insert!(:division_vacation_week_quota, %{
        start_date: Date.add(Date.utc_today(), 30),
        end_date: Date.add(Date.utc_today(), 36),
        quota: 1
      })

      assert %EmployeeVacationPickOverview{
               employee_id: "00001",
               rank: 1,
               job_class: "000100",
               round_id: ^round_id,
               process_id: ^process_id,
               is_below_point_of_forcing: false
             } = EmployeeVacationPickOverview.open_round("00001")
    end

    test "Returns nil if no currently open round" do
      insert_round_with_employees(
        %{
          round_opening_date: Date.add(Date.utc_today(), -5),
          round_closing_date: Date.add(Date.utc_today(), -3)
        },
        %{group_size: 2, employee_count: 2}
      )

      assert nil == EmployeeVacationPickOverview.open_round("00002")
    end

    test "Returns nil if employee not present" do
      assert nil == EmployeeVacationPickOverview.open_round("00002")
    end
  end
end

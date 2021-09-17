defmodule Draft.EmployeeVacationQuotaSummaryTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.EmployeeVacationQuotaSummary

  doctest EmployeeVacationQuotaSummary

  setup do
    insert_round_with_employees(1)
    employee_ranking = Draft.Repo.one!(from(e in Draft.EmployeeRanking))
    {:ok, employee_ranking: employee_ranking}
  end

  describe "get/4" do
    test "Caps total minutes by the maximum_minutes field for weeks", %{
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        maximum_minutes: 2400
      })

      assert %{total_available_minutes: 2400} =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :week
               )
    end

    test "Returns expected anniversary time for weeks", %{employee_ranking: employee_ranking} do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        maximum_minutes: 4800,
        available_after_date: ~D[2021-02-01],
        available_after_weekly_quota: 1
      })

      assert %{
               total_available_minutes: 4800,
               anniversary_date: ~D[2021-02-01],
               minutes_only_available_as_of_anniversary: 2400
             } =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :week
               )
    end

    test "Caps total minutes by the maximum_minutes field for days", %{
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        dated_quota: 1,
        maximum_minutes: 120
      })

      assert %{total_available_minutes: 120, minutes_only_available_as_of_anniversary: 0} =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :day
               )
    end

    test "Returns expected anniversary time for days", %{employee_ranking: employee_ranking} do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        dated_quota: 2,
        maximum_minutes: 2 * 8 * 60,
        available_after_date: ~D[2021-02-01],
        available_after_dated_quota: 1
      })

      assert %{
               total_available_minutes: 960,
               anniversary_date: ~D[2021-02-01],
               minutes_only_available_as_of_anniversary: 480
             } =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :day
               )
    end

    test "reduces available minutes by already selected vacation", %{
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        maximum_minutes: 4800
      })

      insert!(:employee_vacation_selection, %{
        employee_id: "00001",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :week,
        status: :assigned
      })

      assert %{total_available_minutes: 2400} =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :week
               )
    end

    test "looks at the full calendar year for already selected vacation", %{
      employee_ranking: employee_ranking
    } do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        maximum_minutes: 4800
      })

      # earlier in the year
      insert!(:employee_vacation_selection, %{
        employee_id: "00001",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :week,
        status: :assigned
      })

      # later in the year
      insert!(:employee_vacation_selection, %{
        employee_id: "00001",
        start_date: ~D[2021-05-01],
        end_date: ~D[2021-05-07],
        vacation_interval_type: :week,
        status: :assigned
      })

      assert %{total_available_minutes: 0} =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-03-01],
                 ~D[2021-04-01],
                 :week
               )
    end

    test "subtracts both selected vacation and FMLA", %{employee_ranking: employee_ranking} do
      insert!(:employee_vacation_quota, %{
        employee_id: "00001",
        weekly_quota: 2,
        # took a week of FMLA, down from 4800
        maximum_minutes: 2400
      })

      # took 1 week of vacation
      insert!(:employee_vacation_selection, %{
        employee_id: "00001",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :week,
        status: :assigned
      })

      # 2 weeks of vacation - 1 week of FMLA - 1 week of vacation = 0 remaining minutes
      assert %{total_available_minutes: 0} =
               EmployeeVacationQuotaSummary.get(
                 employee_ranking,
                 ~D[2021-01-01],
                 ~D[2021-03-01],
                 :week
               )
    end
  end

  describe "minutes_available_as_of_date/2" do
    test "No anniversary -- returns full minutes available" do
      assert 960 =
               EmployeeVacationQuotaSummary.minutes_available_as_of_date(
                 %{
                   employee_id: "00001",
                   job_class: "000100",
                   total_available_minutes: 960,
                   anniversary_date: nil,
                   minutes_only_available_as_of_anniversary: 0
                 },
                 ~D[2021-01-15]
               )
    end

    test "Anniversary passed -- returns full minutes available" do
      assert 960 =
               EmployeeVacationQuotaSummary.minutes_available_as_of_date(
                 %{
                   employee_id: "00001",
                   job_class: "000100",
                   total_available_minutes: 960,
                   anniversary_date: ~D[2021-02-01],
                   minutes_only_available_as_of_anniversary: 480
                 },
                 ~D[2021-02-15]
               )
    end

    test "Anniversary hasn't passed -- returns full minutes available" do
      assert 480 =
               EmployeeVacationQuotaSummary.minutes_available_as_of_date(
                 %{
                   employee_id: "00001",
                   job_class: "000100",
                   total_available_minutes: 960,
                   anniversary_date: ~D[2021-02-01],
                   minutes_only_available_as_of_anniversary: 480
                 },
                 ~D[2021-01-15]
               )
    end
  end
end

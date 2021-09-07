defmodule Draft.EmployeeVacationSelectionTest do
  @moduledoc false
  use Draft.DataCase, async: true
  import Draft.Factory
  alias Draft.EmployeeVacationSelection

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct for assigned week vacation" do
      emp_vacation_selections =
        EmployeeVacationSelection.from_parts([
          "00001",
          "Weekly",
          "02/11/2021",
          "02/17/2021",
          "Effective",
          "Annual",
          "122",
          "000100"
        ])

      assert %EmployeeVacationSelection{
               employee_id: "00001",
               vacation_interval_type: :week,
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               status: :assigned,
               pick_period: "Annual",
               division_id: "122",
               job_class: "000100"
             } = emp_vacation_selections
    end

    test "Successfully map an ordered list of parts into a struct for cancelled day vacation" do
      emp_vacation_selections =
        EmployeeVacationSelection.from_parts([
          "00001",
          "Dated",
          "02/11/2021",
          "02/17/2021",
          "Cancelled",
          "Annual",
          "122",
          "000100"
        ])

      assert %EmployeeVacationSelection{
               employee_id: "00001",
               vacation_interval_type: :day,
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               status: :cancelled,
               pick_period: "Annual",
               division_id: "122",
               job_class: "000100"
             } = emp_vacation_selections
    end
  end

  describe "assigned_vacation_count/4" do
    test "returns 0 if there are no assigned vacations" do
      assert EmployeeVacationSelection.assigned_vacation_count(
               "00001",
               ~D[2021-01-01],
               ~D[2021-12-31],
               :week
             ) == 0

      assert EmployeeVacationSelection.assigned_vacation_count(
               "00001",
               ~D[2021-01-01],
               ~D[2021-12-31],
               :day
             ) == 0
    end

    test "returns the count of assigned weeks" do
      employee_id = "00001"

      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-06],
        vacation_interval_type: :week
      })

      # cancelled (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-01-07],
        end_date: ~D[2021-01-13],
        vacation_interval_type: :week,
        status: :cancelled
      })

      # day (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-01],
        vacation_interval_type: :day
      })

      # wrong employee (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: "00002",
        start_date: ~D[2021-03-01],
        end_date: ~D[2021-03-06],
        vacation_interval_type: :week
      })

      # out of range (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[1999-01-01],
        end_date: ~D[1999-01-06],
        vacation_interval_type: :week
      })

      assert EmployeeVacationSelection.assigned_vacation_count(
               employee_id,
               ~D[2021-01-01],
               ~D[2021-12-31],
               :week
             ) == 1
    end

    test "returns the count of assigned days" do
      employee_id = "00001"

      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-01],
        vacation_interval_type: :day
      })

      # cancelled (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-01-02],
        end_date: ~D[2021-01-02],
        vacation_interval_type: :day,
        status: :cancelled
      })

      # week (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-06],
        vacation_interval_type: :week
      })

      # wrong employee (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: "00002",
        start_date: ~D[2021-03-01],
        end_date: ~D[2021-03-01],
        vacation_interval_type: :day
      })

      # out of range (ignored)
      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[1999-01-01],
        end_date: ~D[1999-01-01],
        vacation_interval_type: :day
      })

      assert EmployeeVacationSelection.assigned_vacation_count(
               employee_id,
               ~D[2021-01-01],
               ~D[2021-12-31],
               :day
             ) == 1
    end

    test "start/end dates are inclusive" do
      employee_id = "00001"

      insert!(:employee_vacation_selection, %{
        employee_id: employee_id,
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-06],
        vacation_interval_type: :week
      })

      assert EmployeeVacationSelection.assigned_vacation_count(
               employee_id,
               ~D[2021-01-01],
               ~D[2021-01-06],
               :week
             ) == 1

      assert EmployeeVacationSelection.assigned_vacation_count(
               employee_id,
               ~D[2021-01-02],
               ~D[2021-01-06],
               :week
             ) == 0

      assert EmployeeVacationSelection.assigned_vacation_count(
               employee_id,
               ~D[2021-01-01],
               ~D[2021-01-05],
               :week
             ) == 0
    end
  end
end

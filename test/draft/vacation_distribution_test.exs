defmodule Draft.VacationDistributionTest do
  use ExUnit.Case
  use Draft.DataCase
  import Draft.Factory
  alias Draft.VacationDistribution

  describe "to_csv_row/1" do
    test "correct values" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|1|1\n" =
               IO.iodata_to_binary(
                 VacationDistribution.to_csv_row(%VacationDistribution{
                   employee_id: "0001",
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-08],
                   interval_type: :week
                 })
               )
    end

    test "format for unassigned vacation" do
      assert "vacation|0001|1|01/01/2021|01/08/2021|0|1\n" =
               IO.iodata_to_binary(
                 VacationDistribution.to_csv_row(%VacationDistribution{
                   employee_id: "0001",
                   start_date: ~D[2021-01-01],
                   end_date: ~D[2021-01-08],
                   interval_type: :week,
                   status: 0
                 })
               )
    end
  end

  describe "add_distributions_to_run/2" do
    test "Successfully inserts when valid" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      distributions = [
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :week,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-07],
          status: :assigned
        }
      ]

      {:ok, _distributions} = VacationDistribution.add_distributions_to_run(run_id, distributions)

      assert [
               %VacationDistribution{
                 employee_id: "0001",
                 interval_type: :week,
                 start_date: ~D[2021-01-01],
                 end_date: ~D[2021-01-07],
                 status: :assigned
               }
             ] = Repo.all(Draft.VacationDistribution)
    end

    test "Successfully inserts when cancelled" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      distributions = [
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :week,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-07],
          status: :cancelled
        }
      ]

      {:ok, _distributions} = VacationDistribution.add_distributions_to_run(run_id, distributions)

      assert [
               %VacationDistribution{
                 employee_id: "0001",
                 interval_type: :week,
                 start_date: ~D[2021-01-01],
                 end_date: ~D[2021-01-07],
                 status: :cancelled
               }
             ] = Repo.all(Draft.VacationDistribution)
    end
  end

  describe "count_unsynced_assignments_by_date/2" do
    test "Returns empty map if none found" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      assert VacationDistribution.count_unsynced_assignments_by_date(run_id, :week) == %{}
    end

    test "Returns values for the correct interval" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      distributions = [
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :week,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-07],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-03],
          end_date: ~D[2021-01-03],
          status: :assigned
        }
      ]

      {:ok, _distributions} = VacationDistribution.add_distributions_to_run(run_id, distributions)

      assert %{~D[2021-01-03] => 1, ~D[2021-01-02] => 2} =
               VacationDistribution.count_unsynced_assignments_by_date(run_id, :day)
    end

    test "Returns only unsynced distributions" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      distributions = [
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :week,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-07],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :assigned,
          synced_to_hastus: true
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-03],
          end_date: ~D[2021-01-03],
          status: :assigned
        }
      ]

      {:ok, _distributions} = VacationDistribution.add_distributions_to_run(run_id, distributions)

      assert %{~D[2021-01-03] => 1, ~D[2021-01-02] => 1} =
               VacationDistribution.count_unsynced_assignments_by_date(run_id, :day)
    end

    test "Returns only assigned distributions" do
      run_id = insert!(:vacation_distribution_run, %{}).id

      distributions = [
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :week,
          start_date: ~D[2021-01-01],
          end_date: ~D[2021-01-07],
          status: :assigned
        },
        %VacationDistribution{
          employee_id: "0001",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :cancelled
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-02],
          end_date: ~D[2021-01-02],
          status: :assigned,
          synced_to_hastus: false
        },
        %VacationDistribution{
          employee_id: "0002",
          interval_type: :day,
          start_date: ~D[2021-01-03],
          end_date: ~D[2021-01-03],
          status: :assigned
        }
      ]

      {:ok, _distributions} = VacationDistribution.add_distributions_to_run(run_id, distributions)

      assert %{~D[2021-01-03] => 1, ~D[2021-01-02] => 1} =
               VacationDistribution.count_unsynced_assignments_by_date(run_id, :day)
    end
  end
end

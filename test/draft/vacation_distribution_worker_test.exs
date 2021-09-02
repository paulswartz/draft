defmodule Draft.VacationDistributionWorkerTest do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.VacationDistribution
  alias Draft.VacationDistributionWorker

  describe "perform/1" do
    test "Successfully distributes vacation weeks" do
      group =
        insert_round_with_employees_and_vacation(
          :week,
          %{~D[2021-04-04] => 1},
          %{"00001" => 1},
          %{},
          %{"00001" => [~D[2021-04-04]]}
        )

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-04],
                  end_date: ~D[2021-04-10],
                  interval_type: :week,
                  employee_id: "00001"
                }
              ]} =
               VacationDistributionWorker.perform(%Oban.Job{
                 args: %{
                   "round_id" => group.round_id,
                   "process_id" => group.process_id,
                   "group_number" => group.group_number
                 }
               })
    end

    test "Successfully distributes vacation days" do
      group =
        insert_round_with_employees_and_vacation(
          :day,
          %{~D[2021-04-04] => 1},
          %{"00001" => 1},
          %{},
          %{"00001" => [~D[2021-04-04]]}
        )

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-04],
                  end_date: ~D[2021-04-04],
                  interval_type: :day,
                  employee_id: "00001"
                }
              ]} =
               VacationDistributionWorker.perform(%Oban.Job{
                 args: %{
                   "round_id" => group.round_id,
                   "process_id" => group.process_id,
                   "group_number" => group.group_number
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

    test "exports the given distributions" do
      group =
        insert_round_with_employees_and_vacation(
          :week,
          %{~D[2021-04-04] => 1},
          %{"00001" => 1},
          %{},
          %{"00001" => [~D[2021-04-04]]}
        )

      VacationDistributionWorker.perform(%Oban.Job{
        args: %{
          "round_id" => group.round_id,
          "process_id" => group.process_id,
          "group_number" => group.group_number
        }
      })

      assert_received {Draft.Exporter.Send, filename, iodata}

      assert String.contains?(filename, "vacation_distribution")
      assert String.contains?(filename, group.round_id)
      assert String.contains?(filename, group.process_id)
      assert String.contains?(filename, Integer.to_string(group.group_number))

      body = IO.iodata_to_binary(iodata)
      lines = String.split(body, "\n")
      # actual contents of the pipe-separated file are tested in Draft.VacationDistribution
      assert ["vacation|" <> _, ""] = lines
    end
  end
end

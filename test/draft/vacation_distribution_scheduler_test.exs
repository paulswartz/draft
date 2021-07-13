defmodule Draft.VacationDistributionSchedulerTest do
  use ExUnit.Case
  use Draft.DataCase
  import Draft.Factory
  alias Draft.VacationDistributionScheduler

  describe "schedule_distributions/1" do
    test "All distributions are scheduled at correct time" do
      bid_groups =
        Enum.map(1..5, fn group_num ->
          build(:group, %{
            group_number: group_num,
            cutoff_datetime: DateTime.add(DateTime.utc_now(), group_num * 60 * 60 * 24, :second)
          })
        end)

      VacationDistributionScheduler.schedule_distributions(bid_groups)

      assert Enum.map(
               bid_groups,
               &Map.take(&1, [:round_id, :process_id, :group_number, :cutoff_datetime])
             ) ==
               Draft.Repo.all(
                 from j in Oban.Job,
                   where: j.state == "scheduled" and j.queue == "vacation_distribution",
                   select: %{
                     round_id: fragment("?->'round_id'", j.args),
                     process_id: fragment("?->'process_id'", j.args),
                     group_number: fragment("?->'group_number'", j.args),
                     cutoff_datetime: j.scheduled_at
                   }
               )
    end
  end

  describe "cancel_upcoming_distributions/1" do
    test "Only upcoming jobs are marked as cancelled" do
      round = %Draft.BidRound{round_id: "vacation", process_id: "BUS2021-125"}

      Draft.Repo.insert!(
        Draft.VacationDistributionWorker.new(%{
          round_id: round.round_id,
          process_id: round.process_id,
          group_number: 1
        })
      )

      # Force completion of that distribution
      Oban.drain_queue(queue: "vacation_distribution")

      upcoming_group =
        build(:group, %{
          round_id: round.round_id,
          process_id: round.process_id,
          group_number: 2,
          cutoff_datetime: DateTime.add(DateTime.utc_now(), 60 * 60 * 24, :second)
        })

      VacationDistributionScheduler.schedule_distributions([upcoming_group])

      VacationDistributionScheduler.cancel_upcoming_distributions([round])
      assert get_job_for_group!(round.round_id, round.process_id, 1).state == "completed"
      assert get_job_for_group!(round.round_id, round.process_id, 2).state == "cancelled"
    end

    test "Only jobs for the given groups are cancelled" do
      round_to_cancel = %Draft.BidRound{round_id: "vacation", process_id: "BUS2021-125"}

      round_1_groups =
        Enum.map(1..5, fn group_num ->
          build(:group, %{
            round_id: round_to_cancel.round_id,
            process_id: round_to_cancel.process_id,
            group_number: group_num,
            cutoff_datetime: DateTime.add(DateTime.utc_now(), group_num * 60 * 60 * 24, :second)
          })
        end)

      round_2_groups =
        Enum.map(1..5, fn group_num ->
          build(:group, %{
            round_id: round_to_cancel.round_id,
            process_id: "BUS2021-124",
            group_number: group_num,
            cutoff_datetime: DateTime.add(DateTime.utc_now(), group_num * 60 * 60 * 24, :second)
          })
        end)

      round_3_groups =
        Enum.map(1..5, fn group_num ->
          build(:group, %{
            round_id: "work",
            process_id: round_to_cancel.process_id,
            group_number: group_num,
            cutoff_datetime: DateTime.add(DateTime.utc_now(), group_num * 60 * 60 * 24, :second)
          })
        end)

      VacationDistributionScheduler.schedule_distributions(
        round_1_groups ++ round_2_groups ++ round_3_groups
      )

      VacationDistributionScheduler.cancel_upcoming_distributions([round_to_cancel])

      Enum.each(
        get_jobs_for_round(round_to_cancel.round_id, round_to_cancel.process_id),
        fn job -> assert job.state == "cancelled" end
      )

      Enum.each(get_jobs_for_round(round_to_cancel.round_id, "BUS2021-124"), fn job ->
        assert job.state == "scheduled"
      end)

      Enum.each(get_jobs_for_round("work", round_to_cancel.process_id), fn job ->
        assert job.state == "scheduled"
      end)
    end
  end

  defp get_jobs_for_round(round_id, process_id) do
    Draft.Repo.all(
      from j in Oban.Job,
        where:
          j.queue == "vacation_distribution" and
            fragment("?->'round_id'=?", j.args, ^round_id) and
            fragment("?->'process_id'=?", j.args, ^process_id)
    )
  end

  defp get_job_for_group!(round_id, process_id, group_id) do
    Draft.Repo.one!(
      from j in Oban.Job,
        where:
          j.queue == "vacation_distribution" and
            fragment("?->'round_id'=?", j.args, ^round_id) and
            fragment("?->'process_id'=?", j.args, ^process_id) and
            fragment("?->'group_number'=?", j.args, ^group_id)
    )
  end
end

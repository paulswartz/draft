defmodule Draft.VacationDistributionSchedulerTest do
  use ExUnit.Case
  use Draft.DataCase
  use Oban.Testing, repo: Draft.Repo
  import Draft.Factory
  alias Draft.VacationDistributionScheduler

  describe "reset_upcoming_distribution_jobs/2" do
    test "New jobs are scheduled at the correct time for each group" do
      round = build(:round, %{round_id: "vacation", process_id: "BUS2021-125"})

      future_cutoff_1 = DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
      future_cutoff_2 = DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * 2)

      group1 =
        build(:group,
          group_number: 1,
          cutoff_datetime: future_cutoff_1,
          round_id: round.round_id,
          process_id: round.process_id
        )

      group2 =
        build(:group,
          group_number: 2,
          cutoff_datetime: future_cutoff_2,
          round_id: round.round_id,
          process_id: round.process_id
        )

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([], [group1, group2])

      assert %{state: "scheduled", scheduled_at: ^future_cutoff_1} = job_for_group!(group1)
      assert %{state: "scheduled", scheduled_at: ^future_cutoff_2} = job_for_group!(group2)
    end

    test "Existing jobs are rescheduled" do
      round = build(:round, %{round_id: "vacation", process_id: "BUS2021-125"})

      initial_cutoff = DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
      updated_cutoff = DateTime.add(DateTime.utc_now(), 60 * 60 * 24 * 3)

      group1 =
        build(:group,
          group_number: 1,
          cutoff_datetime: initial_cutoff,
          round_id: round.round_id,
          process_id: round.process_id
        )

      group1_updated =
        build(:group,
          group_number: 1,
          cutoff_datetime: updated_cutoff,
          round_id: round.round_id,
          process_id: round.process_id
        )

      group2 =
        build(:group,
          group_number: 2,
          cutoff_datetime: initial_cutoff,
          round_id: round.round_id,
          process_id: round.process_id
        )

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([round], [
        group1,
        group2
      ])

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([round], [
        group1_updated,
        group2
      ])

      assert [
               %{state: "cancelled", scheduled_at: ^initial_cutoff},
               %{state: "scheduled", scheduled_at: ^updated_cutoff}
             ] = all_jobs_for_group(group1)

      assert [
               %{state: "cancelled", scheduled_at: ^initial_cutoff},
               %{state: "scheduled", scheduled_at: ^initial_cutoff}
             ] = all_jobs_for_group(group2)
    end

    test "Only upcoming jobs for the specified rounds are cancelled" do
      round = build(:round, %{round_id: "vacation", process_id: "BUS2021-125"})

      past_group =
        build(:group, %{
          round_id: round.round_id,
          process_id: round.process_id,
          group_number: 1,
          cutoff_datetime: ~U[2021-01-01T00:00:00Z]
        })

      upcoming_group =
        build(:group, %{
          round_id: round.round_id,
          process_id: round.process_id,
          group_number: 2,
          cutoff_datetime: DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
        })

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([round], [
        past_group,
        upcoming_group
      ])

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([round], [])

      assert job_for_group!(past_group).state == "scheduled"
      assert job_for_group!(upcoming_group).state == "cancelled"
    end

    test "Jobs not associated with the given rounds are not cancelled on reset" do
      round_to_cancel = build(:round, %{round_id: "vacation", process_id: "BUS2021-125"})
      round_different_id = build(:round, %{round_id: "work", process_id: "BUS2021-125"})
      round_different_process = build(:round, %{round_id: "vacation", process_id: "BUS2021-124"})

      group_in_round_to_cancel =
        build(:group, %{
          round_id: round_to_cancel.round_id,
          process_id: round_to_cancel.process_id,
          group_number: 1,
          cutoff_datetime: DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
        })

      group_different_round =
        build(:group, %{
          round_id: round_different_id.round_id,
          process_id: round_different_id.process_id,
          group_number: 1,
          cutoff_datetime: DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
        })

      group_different_process =
        build(:group, %{
          round_id: round_different_process.round_id,
          process_id: round_different_process.process_id,
          group_number: 1,
          cutoff_datetime: DateTime.add(DateTime.utc_now(), 60 * 60 * 24)
        })

      VacationDistributionScheduler.reset_upcoming_distribution_jobs([], [
        group_in_round_to_cancel,
        group_different_round,
        group_different_process
      ])
      VacationDistributionScheduler.reset_upcoming_distribution_jobs([round_to_cancel], [])

      assert job_for_group!(group_in_round_to_cancel).state == "cancelled"
      assert job_for_group!(group_different_round).state == "scheduled"
      assert job_for_group!(group_different_process).state == "scheduled"
    end
  end

  defp job_for_group!(%{round_id: round_id, process_id: process_id, group_number: group_id}) do
    Draft.Repo.one!(
      from j in Oban.Job,
        where:
          j.queue == "vacation_distribution" and
            fragment("?->'round_id'=?", j.args, ^round_id) and
            fragment("?->'process_id'=?", j.args, ^process_id) and
            fragment("?->'group_number'=?", j.args, ^group_id)
    )
  end

  defp all_jobs_for_group(%{round_id: round_id, process_id: process_id, group_number: group_id}) do
    Draft.Repo.all(
      from j in Oban.Job,
        where:
          j.queue == "vacation_distribution" and
            fragment("?->'round_id'=?", j.args, ^round_id) and
            fragment("?->'process_id'=?", j.args, ^process_id) and
            fragment("?->'group_number'=?", j.args, ^group_id),
        order_by: j.id
    )
  end
end

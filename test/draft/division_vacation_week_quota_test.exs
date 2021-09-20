defmodule Draft.DivisionVacationWeekQuotaTest do
  @moduledoc false
  use Draft.DataCase
  import Draft.Factory
  alias Draft.DivisionVacationWeekQuota

  describe "from_parts/1" do
    test "Successfully map an ordered list of parts into a struct" do
      div_quota_week =
        DivisionVacationWeekQuota.from_parts([
          "125",
          "FTVacQuota",
          "1",
          "02/11/2021",
          "02/17/2021",
          "5",
          "4",
          "0"
        ])

      assert %DivisionVacationWeekQuota{
               division_id: "125",
               job_class_category: :ft,
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               quota: 4,
               is_restricted_week: false
             } = div_quota_week
    end
  end

  describe "available_quota/3" do
    test "Only includes weeks with quota > 0" do
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
          employee_count: 1,
          group_size: 10
        }
      )

      session = Repo.one!(from(s in Draft.BidSession))

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-15],
        end_date: ~D[2021-02-21],
        quota: 0
      })

      assert [
               %{start_date: ~D[2021-02-08], end_date: ~D[2021-02-14]},
               %{start_date: ~D[2021-02-01], end_date: ~D[2021-02-07]}
             ] = Draft.DivisionVacationWeekQuota.available_quota(session, "00001")
    end

    test "Doesn't include week that conflicts with previously selected vacation" do
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
          employee_count: 1,
          group_size: 10
        }
      )

      session = Repo.one!(from(s in Draft.BidSession))

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        job_class_category: :ft,
        start_date: ~D[2021-02-15],
        end_date: ~D[2021-02-21],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-02-16],
        end_date: ~D[2021-02-16],
        employee_id: "00001"
      })

      assert [
               %{start_date: ~D[2021-02-08], end_date: ~D[2021-02-14]},
               %{start_date: ~D[2021-02-01], end_date: ~D[2021-02-07]}
             ] = Draft.DivisionVacationWeekQuota.available_quota(session, "00001")
    end

    test "Doesn't include days that were refunded to another employee" do
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

      session = Repo.one!(from(s in Draft.BidSession))

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-15],
        end_date: ~D[2021-02-21],
        quota: 2
      })

      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :week,
        employee_id: "00001",
        status: :cancelled
      })

      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-15],
        end_date: ~D[2021-02-21],
        vacation_interval_type: :week,
        employee_id: "00001",
        status: :cancelled
      })

      # different division, should be ignored
      insert!(:employee_vacation_selection, %{
        division_id: "102",
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-14],
        vacation_interval_type: :week,
        employee_id: "00003",
        status: :cancelled
      })

      assert [%{start_date: ~D[2021-02-15], quota: 1}, %{start_date: ~D[2021-02-08]}] =
               Draft.DivisionVacationWeekQuota.available_quota(session, "00002")
    end

    test "does not treat day intervals as a week for purposes of the quota" do
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

      session = Repo.one!(from(s in Draft.BidSession))

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        division_id: "102",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :day,
        employee_id: "00001",
        status: :cancelled
      })

      assert [%{start_date: ~D[2021-02-01]}] =
               Draft.DivisionVacationWeekQuota.available_quota(session, "00002")
    end

    test "does not count cancellations from a different job class" do
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
          employee_count: 1,
          group_size: 10
        }
      )

      session = Repo.one!(from(s in Draft.BidSession))

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      # PT, not full-time
      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        vacation_interval_type: :week,
        employee_id: "00002",
        job_class: "000900",
        status: :cancelled
      })

      assert [%{start_date: ~D[2021-02-01]}] =
               Draft.DivisionVacationWeekQuota.available_quota(session, "00001")
    end
  end

  describe "remaining_quota/1" do
    test "only contains quota within rating period" do
      insert!(
        :round,
        %{division_id: "112", round_id: "vac_FT"}
      )

      session =
        insert!(
          :session,
          %{
            division_id: "112",
            round_id: "vac_FT",
            rating_period_start_date: ~D[2021-08-01],
            rating_period_end_date: ~D[2021-08-28]
          }
        )

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-08],
        end_date: ~D[2021-08-14],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-29],
        end_date: ~D[2021-09-04],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-07-25],
        end_date: ~D[2021-07-31],
        quota: 2
      })

      assert 3 = DivisionVacationWeekQuota.remaining_quota(session)
    end

    test "only contains quota for division" do
      insert!(
        :round,
        %{division_id: "112", round_id: "vac_FT"}
      )

      session =
        insert!(
          :session,
          %{
            division_id: "112",
            round_id: "vac_FT",
            rating_period_start_date: ~D[2021-08-01],
            rating_period_end_date: ~D[2021-08-28]
          }
        )

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "114",
        job_class_category: :ft,
        start_date: ~D[2021-08-08],
        end_date: ~D[2021-08-14],
        quota: 2
      })

      assert 1 = DivisionVacationWeekQuota.remaining_quota(session)
    end

    test "only contains quota for job class category" do
      insert!(
        :round,
        %{division_id: "112", round_id: "vac_FT"}
      )

      session =
        insert!(
          :session,
          %{
            division_id: "112",
            round_id: "vac_FT",
            rating_period_start_date: ~D[2021-08-01],
            rating_period_end_date: ~D[2021-08-28]
          }
        )

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :pt,
        start_date: ~D[2021-08-08],
        end_date: ~D[2021-08-14],
        quota: 2
      })

      assert 1 = DivisionVacationWeekQuota.remaining_quota(session)
    end

    test "Does not include cancelled vacation" do
      insert!(
        :round,
        %{division_id: "112", round_id: "vac_FT"}
      )

      session =
        insert!(
          :session,
          %{
            division_id: "112",
            round_id: "vac_FT",
            rating_period_start_date: ~D[2021-08-01],
            rating_period_end_date: ~D[2021-08-28]
          }
        )

      insert!(:division_vacation_week_quota, %{
        division_id: "112",
        job_class_category: :ft,
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        quota: 2
      })

      insert!(:employee_vacation_selection, %{
        employee_id: "00001",
        division_id: "112",
        vacation_interval_type: :week,
        job_class: "000100",
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        status: :cancelled
      })

      assert 1 = DivisionVacationWeekQuota.remaining_quota(session)
    end
  end
end

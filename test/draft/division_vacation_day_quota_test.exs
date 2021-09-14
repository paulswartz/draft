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
          "5",
          "4"
        ])

      assert %DivisionVacationDayQuota{
               division_id: "125",
               job_class_category: :ft,
               date: ~D[2021-02-11],
               quota: 4
             } = div_quota_dated
    end
  end

  describe "available_quota/2" do
    test "Only includes days with quota > 0" do
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

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-02],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-03],
        quota: 0
      })

      assert [%{date: ~D[2021-02-02]}, %{date: ~D[2021-02-01]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00001")
    end

    test "Doesn't include day that conflicts with previously selected vacation" do
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

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-02],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-03],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        start_date: ~D[2021-02-03],
        end_date: ~D[2021-02-03],
        vacation_interval_type: :day,
        employee_id: "00001"
      })

      assert [%{date: ~D[2021-02-02]}, %{date: ~D[2021-02-01]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00001")
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

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-02],
        quota: 1
      })

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-03],
        quota: 2
      })

      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-01],
        vacation_interval_type: :day,
        employee_id: "00001",
        status: :cancelled
      })

      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-03],
        end_date: ~D[2021-02-03],
        vacation_interval_type: :day,
        employee_id: "00001",
        status: :cancelled
      })

      # different division, should be ignored
      insert!(:employee_vacation_selection, %{
        division_id: "102",
        start_date: ~D[2021-02-02],
        end_date: ~D[2021-02-02],
        vacation_interval_type: :day,
        employee_id: "00003",
        status: :cancelled
      })

      assert [%{date: ~D[2021-02-03], quota: 1}, %{date: ~D[2021-02-02]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00002")
    end

    test "does not treat week intervals as separate days for purposes of the quota" do
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

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        division_id: "102",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-06],
        vacation_interval_type: :week,
        employee_id: "00001",
        status: :cancelled
      })

      assert [%{date: ~D[2021-02-01]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00002")
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

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      # PT, not full-time
      insert!(:employee_vacation_selection, %{
        division_id: "101",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-01],
        vacation_interval_type: :day,
        employee_id: "00002",
        job_class: "000900",
        status: :cancelled
      })

      assert [%{date: ~D[2021-02-01]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00001")
    end

    @tag skip: "TODO: how to model vacation selected in a previous pick?"
    test "Does include days that were refunded to another employee in a previous pick" do
      Draft.Factory.insert_round_with_employees(
        %{
          rank: 1,
          rating_period_start_date: ~D[2021-01-01],
          rating_period_end_date: ~D[2021-01-31],
          process_id: "process_prior",
          round_id: "vacation_prior",
          division_id: "101"
        },
        %{
          employee_count: 1,
          group_size: 10
        }
      )

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

      prior_session =
        Repo.one!(from(s in Draft.BidSession, where: s.process_id == "process_prior"))

      session = Repo.one!(from(s in Draft.BidSession, where: s.process_id == "process_1"))

      insert!(:division_vacation_day_quota, %{
        division_id: "101",
        job_class_category: :ft,
        date: ~D[2021-02-01],
        quota: 1
      })

      insert!(:employee_vacation_selection, %{
        process_id: prior_session,
        start_date: ~D[2021-02-03],
        end_date: ~D[2021-02-03],
        vacation_interval_type: :day,
        employee_id: "00001",
        status: :cancelled
      })

      assert [%{date: ~D[2021-02-01]}] =
               Draft.DivisionVacationDayQuota.available_quota(session, "00002")
    end
  end
end

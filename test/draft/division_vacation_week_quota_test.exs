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
               employee_selection_set: "FTVacQuota",
               start_date: ~D[2021-02-11],
               end_date: ~D[2021-02-17],
               quota: 4,
               is_restricted_week: false
             } = div_quota_week
    end
  end

  describe "all_available_days/3" do
    test "Returns only weeks within the pick date for the given round" do
      insert_round_with_employees(
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
        end_date: ~D[2021-02-15],
        quota: 0
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-01-01],
        end_date: ~D[2021-01-07],
        quota: 2
      })

      available_weeks =
        DivisionVacationWeekQuota.all_available_weeks(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationWeekQuota{start_date: ~D[2021-02-01]}] = available_weeks
    end

    test "Returns only weeks within the appropriate division" do
      insert_round_with_employees(
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

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "102",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-15],
        quota: 1
      })

      available_weeks =
        DivisionVacationWeekQuota.all_available_weeks(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationWeekQuota{start_date: ~D[2021-02-01]}] = available_weeks
    end

    test "Returns only weeks within the appropriate employee set" do
      insert_round_with_employees(
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

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "FTVacQuota",
        start_date: ~D[2021-02-01],
        end_date: ~D[2021-02-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        division_id: "101",
        employee_selection_set: "PTVacQuota",
        start_date: ~D[2021-02-08],
        end_date: ~D[2021-02-15],
        quota: 1
      })

      available_weeks =
        DivisionVacationWeekQuota.all_available_weeks(
          "000100",
          "process_1",
          "vacation_1"
        )

      assert [%DivisionVacationWeekQuota{start_date: ~D[2021-02-01]}] = available_weeks
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

      round = Repo.one!(from(r in Draft.BidRound))
      employee_ranking = Repo.one!(from(e in Draft.EmployeeRanking))

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
        quota: 0
      })

      assert [
               %{start_date: ~D[2021-02-08], end_date: ~D[2021-02-14]},
               %{start_date: ~D[2021-02-01], end_date: ~D[2021-02-07]}
             ] = Draft.DivisionVacationWeekQuota.available_quota(round, employee_ranking)
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

      round = Repo.one!(from(r in Draft.BidRound))
      employee_ranking = Repo.one!(from(e in Draft.EmployeeRanking))

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
             ] = Draft.DivisionVacationWeekQuota.available_quota(round, employee_ranking)
    end
  end

  describe "available_quota_with_preference_rank/2" do
    test "Returns dates in descending order when nil" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      assert [
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionVacationWeekQuota.available_quota_with_preference_rank(round, emp)
    end

    test "Returns dates with preference present before dates w/out preference" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      first_preference_set = %Draft.EmployeeVacationPreferenceSet{
        process_id: process_id,
        round_id: round_id,
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-08-01],
            end_date: ~D[2021-08-07],
            rank: 1,
            interval_type: :week
          }
        ]
      }

      Draft.Repo.insert!(first_preference_set)

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: nil,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionVacationWeekQuota.available_quota_with_preference_rank(round, emp)
    end

    test "Preferences are returned sorted in ascending order" do
      %{round_id: round_id, process_id: process_id} =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 1
          },
          %{
            "00001" => 1
          },
          %{}
        )

      round = Draft.Repo.get_by!(Draft.BidRound, round_id: round_id, process_id: process_id)

      emp =
        Draft.Repo.get_by!(Draft.EmployeeRanking,
          round_id: round_id,
          process_id: process_id,
          employee_id: "00001"
        )

      first_preference_set = %Draft.EmployeeVacationPreferenceSet{
        process_id: process_id,
        round_id: round_id,
        employee_id: "00001",
        vacation_preferences: [
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-08-01],
            end_date: ~D[2021-08-07],
            rank: 1,
            interval_type: :week
          },
          %Draft.EmployeeVacationPreference{
            start_date: ~D[2021-08-15],
            end_date: ~D[2021-08-21],
            rank: 2,
            interval_type: :week
          }
        ]
      }

      Draft.Repo.insert!(first_preference_set)

      assert [
               %{
                 start_date: ~D[2021-08-01],
                 end_date: ~D[2021-08-07],
                 preference_rank: 1,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-15],
                 end_date: ~D[2021-08-21],
                 preference_rank: 2,
                 quota: 1
               },
               %{
                 start_date: ~D[2021-08-08],
                 end_date: ~D[2021-08-14],
                 preference_rank: nil,
                 quota: 1
               }
             ] = Draft.DivisionVacationWeekQuota.available_quota_with_preference_rank(round, emp)
    end
  end
end

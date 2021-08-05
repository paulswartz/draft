defmodule Draft.GenerateVacationDistribution.Forced.Test do
  use Draft.DataCase
  import Draft.Factory
  alias Draft.GenerateVacationDistribution
  alias Draft.VacationDistribution

  describe "permutations_take/2" do
    test "basic case" do
      list = [1, 2, 3]
      n = 2

      expected = [
        [1, 2],
        [1, 3],
        [2, 3]
      ]

      actual = Enum.to_list(GenerateVacationDistribution.Forced.permutations_take(list, n))

      assert actual == expected
    end
  end

  describe "distribute_to_group/4" do
    test "One operator being forced gets the latest available weeks" do
      insert_round_with_employees(
        %{
          round_id: "vacation_1",
          process_id: "process_1",
          rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          rating_period_start_date: ~D[2021-04-01],
          rating_period_end_date: ~D[2021-05-01]
        },
        %{
          employee_count: 1,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_distributions =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-08],
                  end_date: ~D[2021-04-14],
                  interval_type: :week,
                  employee_id: "00001"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-15],
                  end_date: ~D[2021-04-21],
                  interval_type: :week,
                  employee_id: "00001"
                }
              ]} = vacation_distributions
    end

    test "Two operators being forced can take the same day when quota is 2" do
      insert_round_with_employees(
        %{
          round_id: "vacation_1",
          process_id: "process_1",
          rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          rating_period_start_date: ~D[2021-04-01],
          rating_period_end_date: ~D[2021-05-01]
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-01],
        end_date: ~D[2021-04-07],
        quota: 1
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00002",
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_distributions =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-01],
                  end_date: ~D[2021-04-07],
                  interval_type: :week,
                  employee_id: "00002"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-08],
                  end_date: ~D[2021-04-14],
                  interval_type: :week,
                  employee_id: "00001"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-15],
                  end_date: ~D[2021-04-21],
                  interval_type: :week,
                  employee_id: "00001"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-15],
                  end_date: ~D[2021-04-21],
                  interval_type: :week,
                  employee_id: "00002"
                }
              ]} = vacation_distributions
    end

    test "Assigns first operator the second best week in order to ensure valid forcing" do
      insert_round_with_employees(
        %{
          round_id: "vacation_1",
          process_id: "process_1",
          rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          rating_period_start_date: ~D[2021-04-01],
          rating_period_end_date: ~D[2021-05-01]
        },
        %{
          employee_count: 2,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-08],
        end_date: ~D[2021-04-14],
        quota: 2
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 1,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00002",
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_distributions =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:ok,
              [
                %VacationDistribution{
                  start_date: ~D[2021-04-08],
                  end_date: ~D[2021-04-14],
                  interval_type: :week,
                  employee_id: "00001"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-08],
                  end_date: ~D[2021-04-14],
                  interval_type: :week,
                  employee_id: "00002"
                },
                %VacationDistribution{
                  start_date: ~D[2021-04-15],
                  end_date: ~D[2021-04-21],
                  interval_type: :week,
                  employee_id: "00002"
                }
              ]} = vacation_distributions
    end

    test "backtracking can handle case where earlier assignments affect later employees" do
      # Division Quota:
      # 8/22: 1
      # 8/15: 2
      # 8/8: 1
      # 8/1: 1

      # Employee Quota:
      # A: 1. Possible assignments: 8/22, 8/15, 8/8, 8/1
      # B: 3. Possible assignments: 8/15, 8/8, 8/1 (Maybe took 8/22 in the annual)
      # C: 1. Possible assignments: 8/22 (Maybe took 8/1, 8/8, 8/15 in the annual)

      # Focusing on employee B as the "first employee" in the normal case.
      # In a previously explored branch, employee A was assigned 8/22, B was
      # assigned all 3 of their possibilities, C couldn't be assigned
      # anything, so the path was invalid.

      # In the current branch, A was assigned 8/15 instead. B can still be
      # assigned all 3 of their possibilities, which we find in the cache, so
      # we return an empty list. However, now it would be possible to assign
      # employee C 8/22, so this schedule could be valid.

      insert_round_with_employees(
        %{
          round_id: "vacation_1",
          process_id: "process_1",
          rank: 1,
          round_opening_date: ~D[2021-06-01],
          round_closing_date: ~D[2021-07-01],
          rating_period_start_date: ~D[2021-08-01],
          rating_period_end_date: ~D[2021-09-01]
        },
        %{
          employee_count: 3,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-08-01],
        end_date: ~D[2021-08-07],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-08-08],
        end_date: ~D[2021-08-14],
        quota: 1
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-08-15],
        end_date: ~D[2021-08-21],
        quota: 2
      })

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-08-22],
        end_date: ~D[2021-08-28],
        quota: 1
      })

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00001",
          weekly_quota: 1,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 2400
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00002",
          weekly_quota: 3,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 7200
        }
      )

      insert!(
        :employee_vacation_quota,
        %{
          employee_id: "00003",
          weekly_quota: 1,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 2400
        }
      )

      insert!(
        :employee_vacation_selection,
        %{
          employee_id: "00002",
          status: :assigned,
          start_date: ~D[2021-08-22],
          end_date: ~D[2021-08-28]
        }
      )

      insert!(
        :employee_vacation_selection,
        %{
          employee_id: "00003",
          status: :assigned,
          start_date: ~D[2021-08-01],
          end_date: ~D[2021-08-07]
        }
      )

      insert!(
        :employee_vacation_selection,
        %{
          employee_id: "00003",
          status: :assigned,
          start_date: ~D[2021-08-08],
          end_date: ~D[2021-08-14]
        }
      )

      insert!(
        :employee_vacation_selection,
        %{
          employee_id: "00003",
          status: :assigned,
          start_date: ~D[2021-08-15],
          end_date: ~D[2021-08-21]
        }
      )

      {:ok, vacation_assignments} =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      actual = Enum.sort_by(vacation_assignments, &{&1.employee_id, Date.to_erl(&1.start_date)})

      assert [
               %{employee_id: "00001", start_date: ~D[2021-08-15]},
               %{employee_id: "00002", start_date: ~D[2021-08-01]},
               %{employee_id: "00002", start_date: ~D[2021-08-08]},
               %{employee_id: "00002", start_date: ~D[2021-08-15]},
               %{employee_id: "00003", start_date: ~D[2021-08-22]}
             ] = actual
    end

    test "Returns an error if no possible forcing solution found" do
      insert_round_with_employees(
        %{
          round_id: "vacation_1",
          process_id: "process_1",
          rank: 1,
          round_opening_date: ~D[2021-02-01],
          round_closing_date: ~D[2021-03-01],
          rating_period_start_date: ~D[2021-04-01],
          rating_period_end_date: ~D[2021-05-01]
        },
        %{
          employee_count: 1,
          group_size: 10
        }
      )

      insert!(:division_vacation_week_quota, %{
        start_date: ~D[2021-04-15],
        end_date: ~D[2021-04-21],
        quota: 2
      })

      insert!(
        :employee_vacation_quota,
        %{
          weekly_quota: 2,
          dated_quota: 0,
          restricted_week_quota: 0,
          available_after_date: nil,
          available_after_weekly_quota: nil,
          available_after_dated_quota: 0,
          maximum_minutes: 4800
        }
      )

      vacation_assignments =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: "vacation_1",
          process_id: "process_1",
          group_number: 1
        })

      assert {:error, :no_possible_assignments_remaining} == vacation_assignments
    end
  end
end

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
        [2, 1],
        [3, 1],
        [3, 2]
      ]

      actual =
        Enum.to_list(
          GenerateVacationDistribution.Forced.permutations_take(list, n, [], fn x, acc ->
            [x | acc]
          end)
        )

      assert actual == expected
    end

    test "taking more items than there are" do
      list = [1]
      n = 2

      expected = []

      actual =
        Enum.to_list(
          GenerateVacationDistribution.Forced.permutations_take(list, n, [], fn x, acc ->
            [x | acc]
          end)
        )

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
        },
        %{type: :vacation, type_allowed: :week}
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

      group =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1,
            ~D[2021-08-15] => 2,
            ~D[2021-08-22] => 1
          },
          %{
            "00001" => 1,
            "00002" => 3,
            "00003" => 1
          },
          %{
            "00002" => [~D[2021-08-22]],
            "00003" => [~D[2021-08-01], ~D[2021-08-08], ~D[2021-08-15]]
          }
        )

      {:ok, vacation_assignments} = GenerateVacationDistribution.Forced.generate_for_group(group)

      assert [
               %{employee_id: "00002", start_date: ~D[2021-08-01]},
               %{employee_id: "00002", start_date: ~D[2021-08-08]},
               %{employee_id: "00001", start_date: ~D[2021-08-15]},
               %{employee_id: "00002", start_date: ~D[2021-08-15]},
               %{employee_id: "00003", start_date: ~D[2021-08-22]}
             ] = vacation_assignments
    end

    test "internal dates are also taken into account" do
      group =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 2,
            ~D[2021-08-08] => 2,
            ~D[2021-08-15] => 2
          },
          %{
            "00001" => 1,
            "00002" => 3,
            "00003" => 1
          },
          %{
            "00003" => [~D[2021-08-01], ~D[2021-08-08]]
          }
        )

      {:ok, vacation_assignments} = GenerateVacationDistribution.Forced.generate_for_group(group)

      assert [
               %{employee_id: "00002", start_date: ~D[2021-08-01]},
               %{employee_id: "00001", start_date: ~D[2021-08-08]},
               %{employee_id: "00002", start_date: ~D[2021-08-08]},
               %{employee_id: "00002", start_date: ~D[2021-08-15]},
               %{employee_id: "00003", start_date: ~D[2021-08-15]}
             ] = vacation_assignments
    end

    test "with many employees, completes in a reasonable amount of time" do
      # worse case scenario: last employee must be forced into last (most-preferred) date
      group =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 2,
            ~D[2021-08-08] => 2,
            ~D[2021-08-15] => 2,
            ~D[2021-08-22] => 2,
            ~D[2021-08-29] => 2,
            ~D[2021-09-01] => 2,
            ~D[2021-09-08] => 2,
            ~D[2021-09-15] => 2,
            ~D[2021-09-22] => 2,
            ~D[2021-09-29] => 2,
            ~D[2021-10-07] => 2,
            ~D[2021-10-14] => 2
          },
          %{
            "00001" => 1,
            "00002" => 1,
            "00003" => 1,
            "00004" => 1,
            "00005" => 1,
            "00006" => 1,
            "00007" => 1,
            "00008" => 1,
            "00009" => 1,
            "00010" => 1,
            "00011" => 1,
            "00012" => 1,
            "00013" => 1,
            "00014" => 1,
            "00015" => 1,
            "00016" => 1,
            "00017" => 1,
            "00018" => 1,
            "00019" => 1,
            "00020" => 1,
            "00021" => 1,
            "00022" => 1,
            "00023" => 1,
            "00024" => 1
          },
          %{
            "00024" => [
              ~D[2021-08-01],
              ~D[2021-08-08],
              ~D[2021-08-15],
              ~D[2021-08-22],
              ~D[2021-08-29],
              ~D[2021-09-01],
              ~D[2021-09-08],
              ~D[2021-09-15],
              ~D[2021-09-22],
              ~D[2021-09-29],
              ~D[2021-10-07]
            ]
          }
        )

      {:ok, vacation_assignments} = GenerateVacationDistribution.Forced.generate_for_group(group)

      last_assignment = Enum.at(vacation_assignments, -1)
      assert %{employee_id: "00024", start_date: ~D[2021-10-14]} = last_assignment
    end

    test "with few employees and larger quotas, completes in a reasonable amount of time" do
      # worse case scenario: last employee must be forced into last (most-preferred) date
      group =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 2,
            ~D[2021-08-08] => 2,
            ~D[2021-08-15] => 2,
            ~D[2021-08-22] => 2,
            ~D[2021-08-29] => 2,
            ~D[2021-09-01] => 2,
            ~D[2021-09-08] => 2,
            ~D[2021-09-15] => 2,
            ~D[2021-09-22] => 2,
            ~D[2021-09-29] => 2,
            ~D[2021-10-07] => 2,
            ~D[2021-10-14] => 1
          },
          %{
            "00001" => 6,
            "00002" => 6,
            "00003" => 6,
            "00004" => 5
          },
          %{
            "00004" => [
              ~D[2021-08-01],
              ~D[2021-08-08],
              ~D[2021-08-15],
              ~D[2021-08-22],
              ~D[2021-08-29],
              ~D[2021-09-01],
              ~D[2021-09-08]
            ]
          }
        )

      {:ok, vacation_assignments} = GenerateVacationDistribution.Forced.generate_for_group(group)
      # {:ok, {:ok, vacation_assignments}} =
      #   :eprof.profile(fn -> GenerateVacationDistribution.Forced.generate_for_group(group) end)

      # :eprof.analyze(:total, filter: [calls: 100])
      assignments = Enum.filter(vacation_assignments, &(&1.employee_id == "00004"))
      assert [_, _, _, _, %{start_date: ~D[2021-10-14]}] = assignments
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

      assert vacation_assignments == :error
    end

    test "Assigns employee their top preference when possible" do
      group =
        insert_round_with_employees_and_vacation(
          %{
            ~D[2021-08-01] => 1,
            ~D[2021-08-08] => 1
          },
          %{
            "00001" => 1,
            "00002" => 1
          },
          %{}
        )

      first_preference_set = %Draft.EmployeeVacationPreferenceSet{
        process_id: group.process_id,
        round_id: group.round_id,
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

      vacation_assignments =
        GenerateVacationDistribution.Forced.generate_for_group(%{
          round_id: group.round_id,
          process_id: group.process_id,
          group_number: group.group_number
        })

      assert {:ok,
              [
                %{employee_id: "00001", start_date: ~D[2021-08-01], preference_rank: 1},
                %{employee_id: "00002", start_date: ~D[2021-08-08], preference_rank: nil}
              ]} = vacation_assignments
    end
  end

  test "WMP Scenario 6 -- Draft finds optimal solution" do
    # Expecting outcome on slide 36 here
    # https://massdot.app.box.com/s/d4iuxl2wvum2caoj9lvarll2s9scnopg/file/820171090750

    week_desc = %{
      ~D[2021-08-01] => :week_1,
      ~D[2021-08-08] => :week_2,
      ~D[2021-08-15] => :week_3,
      ~D[2021-08-22] => :week_4,
      ~D[2021-08-29] => :week_5
    }

    group =
      insert_round_with_employees_and_vacation(
        %{
          # week 1
          ~D[2021-08-01] => 10,
          # week 2
          ~D[2021-08-08] => 6,
          # week 3
          ~D[2021-08-15] => 4,
          # week 4
          ~D[2021-08-22] => 3,
          # week 5
          ~D[2021-08-29] => 2
        },
        %{
          "00001" => 0,
          "00002" => 1,
          "00003" => 1,
          "00004" => 1,
          "00005" => 2,
          "00006" => 2,
          "00007" => 2,
          "00008" => 2,
          "00009" => 2,
          "00010" => 2,
          "00011" => 2,
          "00012" => 2,
          "00013" => 2,
          "00014" => 2,
          "00015" => 2
        },
        %{},
        %{
          "00001" => [~D[2021-08-29], ~D[2021-08-15]],
          "00002" => [~D[2021-08-22], ~D[2021-08-01]],
          "00003" => [~D[2021-08-29], ~D[2021-08-15]],
          "00004" => [~D[2021-08-29], ~D[2021-08-22]],
          "00005" => [~D[2021-08-22], ~D[2021-08-08]],
          "00006" => [~D[2021-08-29], ~D[2021-08-15]],
          "00007" => [~D[2021-08-22], ~D[2021-08-01]],
          "00008" => [~D[2021-08-29], ~D[2021-08-15]],
          "00009" => [~D[2021-08-29], ~D[2021-08-15]],
          "00010" => [~D[2021-08-22], ~D[2021-08-15]],
          "00011" => [~D[2021-08-22], ~D[2021-08-08]],
          "00012" => [~D[2021-08-29], ~D[2021-08-15]],
          "00013" => [~D[2021-08-29], ~D[2021-08-22]],
          "00014" => [~D[2021-08-22], ~D[2021-08-01]],
          "00015" => [~D[2021-08-08], ~D[2021-08-01]]
        }
      )

    {:ok, vacation_assignments} = GenerateVacationDistribution.Forced.generate_for_group(group)

    vacation_assignments_formatted =
      Enum.group_by(vacation_assignments, & &1.employee_id, &Map.get(week_desc, &1.start_date))

    expected_assignments = %{
      "00002" => [:week_4],
      "00003" => [:week_5],
      "00004" => [:week_5],
      "00005" => [:week_2, :week_4],
      "00006" => [:week_1, :week_3],
      "00007" => [:week_1, :week_4],
      "00008" => [:week_1, :week_3],
      "00009" => [:week_1, :week_3],
      "00010" => [:week_1, :week_3],
      "00011" => [:week_1, :week_2],
      "00012" => [:week_1, :week_2],
      "00013" => [:week_1, :week_2],
      "00014" => [:week_1, :week_2],
      "00015" => [:week_1, :week_2]
    }

    assert ^expected_assignments = vacation_assignments_formatted
  end
end

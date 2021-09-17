defmodule Draft.Factory do
  @moduledoc """
  Factory for building & inserting test data into the database
  """
  alias Draft.Repo

  @spec build(
          :division_vacation_day_quota
          | :division_vacation_week_quota
          | :employee_ranking
          | :employee_vacation_quota
          | :employee_vacation_selection
          | :group
          | :round
          | :session
          | :roster_set
          | :roster_availability
          | :roster_day
          | :vacation_preference_set
        ) :: struct()
  def build(:round) do
    %Draft.BidRound{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      round_opening_date: ~D[2021-02-09],
      round_closing_date: ~D[2021-03-03],
      bid_type: :vacation,
      rank: 1,
      service_context: nil,
      division_id: "122",
      division_description: "Arborway",
      booking_id: "BUS22021",
      rating_period_start_date: ~D[2021-03-14],
      rating_period_end_date: ~D[2021-06-19]
    }
  end

  def build(:session) do
    %Draft.BidSession{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      session_id: "Vacation_FT",
      booking_id: "BUS22021",
      job_class_category: :ft,
      type: :vacation,
      type_allowed: :week,
      division_id: "122",
      service_context: nil,
      scheduling_unit: nil,
      rating_period_start_date: ~D[2021-03-14],
      rating_period_end_date: ~D[2021-06-19]
    }
  end

  def build(:roster_set) do
    %Draft.RosterSet{
      booking_id: "BUS22021",
      session_id: "FT_Work",
      scheduling_unit: "Rsc122",
      roster_set_id: "roster_set_id",
      roster_set_internal_id: 1234,
      scenario: 1,
      service_context: "base"
    }
  end

  def build(:roster_availability) do
    %Draft.RosterAvailability{
      booking_id: "BUS22021",
      session_id: "FT_Work",
      roster_set_id: "roster_set_id",
      roster_set_internal_id: 1234,
      roster_id: "1-BB",
      work_off_ratio: :five_two,
      is_available: true
    }
  end

  def build(:roster_day) do
    %Draft.RosterDay{
      booking_id: "BUS22021",
      roster_set_id: "roster_set_id",
      roster_set_internal_id: 1234,
      roster_id: "1-BB",
      roster_position_id: "122155",
      roster_position_internal_id: 0,
      day: "Monday",
      assignment: "LR08",
      duty_internal_id: nil,
      crew_schedule_internal_id: 4321
    }
  end

  def build(:group) do
    %Draft.BidGroup{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      group_number: 1,
      cutoff_datetime: ~U[2021-02-11 22:00:00Z]
    }
  end

  def build(:employee_ranking) do
    %Draft.EmployeeRanking{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      group_number: 1,
      rank: 1,
      employee_id: "00001",
      name: "test_name",
      job_class: "000100"
    }
  end

  def build(:employee_vacation_selection) do
    %Draft.EmployeeVacationSelection{
      employee_id: "00001",
      vacation_interval_type: :week,
      start_date: ~D[2021-02-11],
      end_date: ~D[2021-02-17],
      pick_period: "Annual",
      status: :assigned,
      division_id: "122",
      job_class: "000100"
    }
  end

  def build(:employee_vacation_quota) do
    weekly_quota = 2

    %Draft.EmployeeVacationQuota{
      employee_id: "00001",
      interval_start_date: ~D[2021-01-01],
      interval_end_date: ~D[2021-12-31],
      weekly_quota: weekly_quota,
      dated_quota: 5,
      restricted_week_quota: 0,
      available_after_date: nil,
      available_after_weekly_quota: 0,
      available_after_dated_quota: 0,
      maximum_minutes: weekly_quota * 40 * 60
    }
  end

  def build(:division_vacation_day_quota) do
    %Draft.DivisionVacationDayQuota{
      division_id: "122",
      employee_selection_set: "FTVacQuota",
      job_class_category: :ft,
      date: ~D[2021-02-11],
      quota: 5
    }
  end

  def build(:division_vacation_week_quota) do
    %Draft.DivisionVacationWeekQuota{
      division_id: "122",
      employee_selection_set: "FTVacQuota",
      job_class_category: :ft,
      start_date: ~D[2021-02-11],
      end_date: ~D[2021-02-17],
      quota: 5,
      is_restricted_week: false
    }
  end

  def build(:vacation_distribution_run) do
    %Draft.VacationDistributionRun{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      start_time: DateTime.truncate(DateTime.utc_now(), :second)
    }
  end

  def build(:vacation_preference_set) do
    %Draft.EmployeeVacationPreferenceSet{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      employee_id: "00001",
      vacation_preferences: []
    }
  end

  def build(:work_assignment) do
    %Draft.WorkAssignment{
      employee_id: "00001",
      assignment: "LR08",
      hours_worked: nil,
      duty_internal_id: 1001,
      is_dated_exception: false,
      is_from_primary_pick: true,
      is_vr: false,
      division_id: "122",
      job_class: "000100",
      operating_date: ~D[2021-08-23],
      roster_set_internal_id: 1234
    }
  end

  # Convenience API

  @spec build(
          :division_vacation_day_quota
          | :division_vacation_week_quota
          | :employee_ranking
          | :employee_vacation_quota
          | :employee_vacation_selection
          | :group
          | :round
          | :session
          | :roster_set
          | :roster_availability
          | :roster_day
          | :vacation_preference_set,
          map()
        ) :: struct
  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  @spec insert!(
          :division_vacation_day_quota
          | :division_vacation_week_quota
          | :employee_ranking
          | :employee_vacation_quota
          | :employee_vacation_selection
          | :group
          | :round
          | :session
          | :roster_set
          | :roster_availability
          | :roster_day
          | :vacation_preference_set,
          map()
        ) :: struct()
  def insert!(factory_name, attributes \\ %{}) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  @spec insert_work_round([
          %{
            session_id: String.t(),
            roster_set_internal_id: integer(),
            available_rosters: %{
              work_off_ratio: Draft.WorkOffRatio.t() | nil,
              is_available: boolean(),
              id: String.t(),
              roster_days: [%{day: String.t(), duty_id: integer() | nil}]
            }
          }
        ]) :: :ok
  def insert_work_round(sessions) do
    insert!(:round)
    Enum.each(sessions, &insert_session_with_rosters(&1))
  end

  defp insert_session_with_rosters(session) do
    roster_set_id = Integer.to_string(session.roster_set_internal_id)

    insert!(:session, %{
      type: :work,
      type_allowed: nil,
      service_context: "Base",
      scheduling_unit: "Rsc122",
      session_id: session.session_id
    })

    insert!(:roster_set, %{
      session_id: session.session_id,
      roster_set_internal_id: session.roster_set_internal_id,
      roster_set_id: roster_set_id
    })

    session.available_rosters
    |> Enum.map(
      &Map.merge(&1, %{
        roster_set_internal_id: session.roster_set_internal_id,
        roster_set_id: roster_set_id,
        session_id: session.session_id
      })
    )
    |> Enum.each(&insert_available_roster_with_days(&1))
  end

  defp insert_available_roster_with_days(available_roster) do
    insert!(:roster_availability, %{
      work_off_ratio: available_roster.work_off_ratio,
      session_id: available_roster.session_id,
      roster_set_internal_id: available_roster.roster_set_internal_id,
      roster_id: available_roster.roster_id,
      roster_set_id: available_roster.roster_set_id
    })

    Enum.each(
      available_roster.roster_days,
      &insert!(:roster_day, %{
        roster_set_internal_id: available_roster.roster_set_internal_id,
        roster_id: available_roster.roster_id,
        roster_set_id: available_roster.roster_set_id,
        day: &1.day,
        duty_internal_id: &1.duty_id
      })
    )
  end

  @spec insert_round_with_employees(integer()) :: Draft.BidRound.t()
  @doc """
    Insert a default round with the given number of employees in a single group
  """
  def insert_round_with_employees(employee_count) do
    insert_round_with_employees(%{}, %{group_size: employee_count, employee_count: employee_count})
  end

  @spec insert_round_with_employees(
          map(),
          %{
            :employee_count => integer(),
            :group_size => integer()
          },
          map()
        ) :: Draft.BidRound.t()
  @doc """
  Insert a single round with the given specifications the specified number of employees, broken into the specified number of groups.
  Employee ids are created with 0 padding to be 5 digits.
  """
  def insert_round_with_employees(
        round_attrs,
        %{
          employee_count: employee_count,
          group_size: group_size
        },
        session_attrs \\ %{type: :vacation, type_allowed: :week}
      ) do
    inserted_round = Draft.Factory.insert!(:round, round_attrs)

    session_attrs =
      inserted_round
      |> Map.from_struct()
      |> Map.take([
        :round_id,
        :process_id,
        :rating_period_start_date,
        :rating_period_end_date,
        :service_context,
        :division_id,
        :booking_id
      ])
      |> Map.merge(session_attrs)
      |> Map.put(:session_id, "session_id_#{:erlang.unique_integer([:positive])}")

    Draft.Factory.insert!(:session, session_attrs)

    grouped_employees = Enum.with_index(Enum.chunk_every(1..employee_count, group_size), 1)

    Enum.each(grouped_employees, fn {group, index} ->
      inserted_group =
        Draft.Factory.insert!(:group, %{
          group_number: index,
          round_id: inserted_round.round_id,
          process_id: inserted_round.process_id
        })

      Enum.each(Enum.with_index(group, 1), fn {emp_id, emp_rank} ->
        Draft.Factory.insert!(
          :employee_ranking,
          %{
            group_number: index,
            round_id: inserted_group.round_id,
            process_id: inserted_group.process_id,
            rank: emp_rank,
            employee_id: String.pad_leading(Integer.to_string(emp_id), 5, "0")
          }
        )
      end)
    end)

    inserted_round
  end

  @doc """
  Given a map of dates => quota, a map of employee_id => quota, and a map of
  employee_id => list of existing vacation dates, creates a round/group and
  the relevant quotas.  Returns a map suitable for passing to
  Draft.GenerateVacationDistribution.Forced.generate_for_group/1.
  """
  @spec insert_round_with_employees_and_vacation(
          Draft.IntervalType.t(),
          %{Date.t() => pos_integer()},
          %{
            String.t() =>
              pos_integer()
              | %{
                  :total_quota => pos_integer(),
                  optional(:anniversary_date) => Date.t(),
                  optional(:anniversary_quota) => pos_integer()
                }
          },
          %{String.t() => [Date.t()]},
          %{String.t() => [Date.t()]}
        ) :: %{round_id: String.t(), process_id: String.t(), group_number: pos_integer()}
  def insert_round_with_employees_and_vacation(
        interval_type,
        start_date_to_quota,
        employee_to_date_quota,
        existing_vacation,
        vacation_preferences \\ %{}
      ) do
    dates = Enum.sort_by(Map.keys(start_date_to_quota), &Date.to_erl/1)
    employee_count = map_size(employee_to_date_quota)

    start_date = Enum.at(dates, 0)
    last_date = Enum.at(dates, -1)
    unique_int = :erlang.unique_integer([:positive])
    round_id = "round_#{unique_int}"
    process_id = "process_#{unique_int}"

    insert_round_with_employees(
      %{
        round_id: round_id,
        process_id: process_id,
        rank: 1,
        round_opening_date: Date.add(start_date, -180),
        round_closing_date: Date.add(start_date, -165),
        rating_period_start_date: start_date,
        rating_period_end_date: end_of_week(last_date)
      },
      %{
        employee_count: employee_count,
        group_size: employee_count
      },
      %{type: :vacation, type_allowed: interval_type}
    )

    insert_quotas(start_date_to_quota, interval_type)
    insert_employee_quotas(employee_to_date_quota, interval_type)
    insert_vacation_selections(existing_vacation)
    insert_vacation_preferences(round_id, process_id, vacation_preferences, interval_type)

    %{
      round_id: round_id,
      process_id: process_id,
      group_number: 1
    }
  end

  defp end_of_week(date) do
    Date.add(date, 6)
  end

  defp end_of_interval(date, :day) do
    date
  end

  defp end_of_interval(date, :week) do
    end_of_week(date)
  end

  defp insert_quotas(start_date_to_quota, :week) do
    for {start_date, quota} <- start_date_to_quota do
      insert!(:division_vacation_week_quota, %{
        start_date: start_date,
        end_date: end_of_week(start_date),
        quota: quota
      })
    end
  end

  defp insert_quotas(start_date_to_quota, :day) do
    for {start_date, quota} <- start_date_to_quota do
      insert!(:division_vacation_day_quota, %{
        date: start_date,
        quota: quota
      })
    end
  end

  defp insert_employee_quotas(employee_to_date_quotas, interval_type) do
    for {employee_id, quota} <- employee_to_date_quotas do
      insert_employee_quota(employee_id, quota, interval_type)
    end
  end

  defp insert_employee_quota(employee_id, quota, interval_type) when is_integer(quota) do
    insert_employee_quota(employee_id, %{total_quota: quota}, interval_type)
  end

  defp insert_employee_quota(employee_id, quota, :week) do
    total_quota = Map.get(quota, :total_quota)
    anniversary = Map.get(quota, :anniversary_date)
    anniversary_quota = Map.get(quota, :anniversary_quota)

    insert!(
      :employee_vacation_quota,
      %{
        employee_id: employee_id,
        weekly_quota: total_quota,
        dated_quota: 0,
        restricted_week_quota: 0,
        available_after_date: anniversary,
        available_after_weekly_quota: anniversary_quota,
        available_after_dated_quota: 0,
        maximum_minutes: 2400 * total_quota
      }
    )
  end

  defp insert_employee_quota(employee_id, quota, :day) do
    total_quota = Map.get(quota, :total_quota)
    anniversary = Map.get(quota, :anniversary_date)
    anniversary_quota = Map.get(quota, :anniversary_quota)

    insert!(
      :employee_vacation_quota,
      %{
        employee_id: employee_id,
        weekly_quota: 0,
        dated_quota: total_quota,
        restricted_week_quota: 0,
        available_after_date: anniversary,
        available_after_weekly_quota: 0,
        available_after_dated_quota: anniversary_quota,
        maximum_minutes: 480 * total_quota
      }
    )
  end

  defp insert_vacation_selections(existing_vacation) do
    for {employee_id, vacation_selections} <- existing_vacation,
        week_start <- vacation_selections do
      insert!(
        :employee_vacation_selection,
        %{
          employee_id: employee_id,
          status: :assigned,
          start_date: week_start,
          end_date: Date.add(week_start, 6)
        }
      )
    end
  end

  @spec insert_vacation_preferences(
          String.t(),
          String.t(),
          %{String.t() => [Date.t()]},
          Draft.IntervalType.t()
        ) :: nil | [Draft.EmployeeVacationPreferenceSet.t()]
  @doc """
  Insert the specified employee vacation preferences, given in order of descending preference,
  so the first date is assumed to be the most preferred.
  Ex: if the vacation_preferences param is %{"00001" => [~D[2021-01-01], ~D[2021-01-02]]},
  1/1/2021 would be inserted as operator 00001's top preference.
  """
  def insert_vacation_preferences(_round_id, _process_id, vacation_preferences, _interval_type)
      when vacation_preferences == %{} do
  end

  def insert_vacation_preferences(round_id, process_id, vacation_preferences, interval_type) do
    for {employee_id, preferences} <- vacation_preferences do
      insert!(:vacation_preference_set, %{
        round_id: round_id,
        process_id: process_id,
        employee_id: employee_id,
        vacation_preferences:
          Enum.map(Enum.with_index(preferences, 1), fn {start_date, rank} ->
            %Draft.EmployeeVacationPreference{
              start_date: start_date,
              rank: rank,
              interval_type: interval_type,
              end_date: end_of_interval(start_date, interval_type)
            }
          end)
      })
    end
  end
end

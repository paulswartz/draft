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
        ) :: struct()
  def build(:round) do
    %Draft.BidRound{
      process_id: "BUS22021-122",
      round_id: "Vacation",
      round_opening_date: ~D[2021-02-09],
      round_closing_date: ~D[2021-03-03],
      bid_type: "Vacation",
      rank: 1,
      service_context: nil,
      division_id: "122",
      division_description: "Arborway",
      booking_id: "BUS22021",
      rating_period_start_date: ~D[2021-03-14],
      rating_period_end_date: ~D[2021-06-19]
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
      vacation_interval_type: "Weekly",
      start_date: ~D[2021-02-11],
      end_date: ~D[2021-02-17],
      pick_period: "Annual"
    }
  end

  def build(:employee_vacation_quota) do
    %Draft.EmployeeVacationQuota{
      employee_id: "00001",
      interval_start_date: ~D[2021-01-01],
      interval_end_date: ~D[2021-12-31],
      weekly_quota: 2,
      dated_quota: 5,
      restricted_week_quota: 0,
      available_after_date: nil,
      available_after_weekly_quota: 0,
      available_after_dated_quota: 0,
      maximum_minutes: 600
    }
  end

  def build(:division_vacation_day_quota) do
    %Draft.DivisionVacationDayQuota{
      division_id: "122",
      employee_selection_set: "FTVacQuota",
      date: ~D[2021-02-11],
      quota: 5
    }
  end

  def build(:division_vacation_week_quota) do
    %Draft.DivisionVacationWeekQuota{
      division_id: "122",
      employee_selection_set: "FTVacQuota",
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

  # Convenience API

  @spec build(
          :division_vacation_day_quota
          | :division_vacation_week_quota
          | :employee_ranking
          | :employee_vacation_quota
          | :employee_vacation_selection
          | :group
          | :round,
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
          | :round,
          map()
        ) :: struct()
  def insert!(factory_name, attributes) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  @spec insert_round_with_employees(%{
          :employee_count => integer(),
          :group_size => integer(),
          :round_closing_date => Date.t(),
          :round_opening_date => Date.t(),
          :round_rank => integer()
        }) :: :ok
  @doc """
  Insert a single round with the specified number of employees, broken into the specified number of groups.
  Employee ids are created with 0 padding to be 5 digits.
  """
  def insert_round_with_employees(%{
        round_rank: round_rank,
        round_opening_date: round_opening_date,
        round_closing_date: round_closing_date,
        employee_count: employee_count,
        group_size: group_size
      }) do
    insert_round_with_employees(
      %{
        rank: round_rank,
        round_opening_date: round_opening_date,
        round_closing_date: round_closing_date
      },
      %{
        employee_count: employee_count,
        group_size: group_size
      }
    )
  end

  @spec insert_round_with_employees(map(), %{
          :employee_count => integer(),
          :group_size => integer()
        }) :: :ok
  @doc """
  Insert a single round with the given specifications the specified number of employees, broken into the specified number of groups.
  Employee ids are created with 0 padding to be 5 digits.
  """
  def insert_round_with_employees(round_attrs, %{
        employee_count: employee_count,
        group_size: group_size
      }) do
    inserted_round = Draft.Factory.insert!(:round, round_attrs)

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
  end
end

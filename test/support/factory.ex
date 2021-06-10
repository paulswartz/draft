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
      available_after_date: ~D[2021-06-30],
      available_after_weekly_quota: 1,
      available_after_dated_quota: 5,
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
end

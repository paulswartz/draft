defmodule Draft.BidRound do
  @moduledoc """
  A Bid Round defines for a given division what type of selection employees are making (work vs. vacation), what period they will be picking preferences for, and when they will be able to pick.
  """
  @behaviour Draft.Parsable

  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.ParsingHelpers

  @type t :: %__MODULE__{
          bid_type: Draft.BidType.t(),
          booking_id: String.t(),
          division_description: String.t(),
          division_id: String.t(),
          process_id: String.t(),
          rank: integer(),
          rating_period_end_date: Date.t(),
          rating_period_start_date: Date.t(),
          round_closing_date: Date.t(),
          round_id: String.t(),
          round_opening_date: Date.t(),
          service_context: String.t() | nil
        }

  @primary_key false
  schema "bid_rounds" do
    field :bid_type, Draft.BidType
    field :booking_id, :string
    field :division_description, :string
    field :division_id, :string
    field :process_id, :string, primary_key: true
    field :rank, :integer
    field :rating_period_end_date, :date
    field :rating_period_start_date, :date
    field :round_closing_date, :date
    field :round_id, :string, primary_key: true
    field :round_opening_date, :date
    field :service_context, :string

    timestamps(type: :utc_datetime)
  end

  @impl Draft.Parsable
  def from_parts(row) do
    [
      process_id,
      round_id,
      round_opening_date,
      round_closing_date,
      bid_type,
      rank,
      service_context,
      division_id,
      division_description,
      booking_id,
      rating_period_start_date,
      rating_period_end_date
    ] = row

    %__MODULE__{
      process_id: process_id,
      round_id: round_id,
      round_opening_date: ParsingHelpers.to_date(round_opening_date),
      round_closing_date: ParsingHelpers.to_date(round_closing_date),
      bid_type: Draft.BidType.from_hastus(bid_type),
      rank: String.to_integer(rank),
      service_context: service_context,
      division_id: division_id,
      division_description: division_description,
      booking_id: booking_id,
      rating_period_start_date: ParsingHelpers.to_date(rating_period_start_date),
      rating_period_end_date: ParsingHelpers.to_date(rating_period_end_date)
    }
  end

  @spec calculate_point_of_equivalence(Draft.BidRound.t()) :: %{
          amount_to_force: integer(),
          employees_to_force: [{String, t(), integer()}],
          has_poe_been_reached: boolean()
        }
  @doc """
  Return whether or not the point of equivalence has been hit yet in the given round,
  and which operators would be forced in order to fill the desired amount of quota to force,
  assuming that no remaining operators want to voluntarily take vacation.
  """
  def calculate_point_of_equivalence(round) do
    quota_to_force = Draft.DivisionVacationWeekQuota.remaining_quota(round)
    employees_desc = Draft.EmployeeRanking.all_remaining_employees(round, :desc)

    {employees_to_force, _acc_employee_quota} =
      Enum.reduce_while(employees_desc, {[], 0}, fn %{employee_id: employee_id} = employee_ranking,
                                                    {acc_employees_to_force, acc_quota} ->
        employee_quota = Draft.EmployeeVacationQuota.week_quota!(round, employee_ranking)

        if employee_quota + acc_quota < quota_to_force do
          {:cont,
           {[{employee_id, employee_quota} | acc_employees_to_force], acc_quota + employee_quota}}
        else
          emp_quota_to_force = quota_to_force - acc_quota

          {:halt,
           {[{employee_id, emp_quota_to_force} | acc_employees_to_force],
            acc_quota + emp_quota_to_force}}
        end
      end)

    %{
      amount_to_force: quota_to_force,
      has_poe_been_reached: length(employees_to_force) == length(employees_desc),
      employees_to_force: employees_to_force
    }
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(bid_round, attrs \\ %{}) do
    bid_round
    |> cast(attrs, [
      :process_id,
      :round_id,
      :round_opening_date,
      :round_closing_date,
      :bid_type,
      :rank,
      :service_context,
      :division_id,
      :division_description,
      :booking_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
    |> validate_required([
      :process_id,
      :round_id,
      :round_opening_date,
      :round_closing_date,
      :bid_type,
      :rank,
      :division_id,
      :division_description,
      :booking_id,
      :rating_period_start_date,
      :rating_period_end_date
    ])
  end
end

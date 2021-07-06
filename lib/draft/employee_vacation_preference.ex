defmodule Draft.EmployeeVacationPreference do
  @moduledoc """
  Represents a single vacation interval (week or day) that an employee has marked as a preference.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.EmployeeVacationPreferenceSet

  @type t :: %__MODULE__{
          preference_set_id: integer(),
          interval_type: Draft.IntervalTypeEnum,
          start_date: Date.t(),
          end_date: Date.t(),
          rank: integer()
        }

  @derive {Jason.Encoder,
           only: [:preference_set_id, :interval_type, :start_date, :end_date, :rank]}

  schema "employee_vacation_preferences" do
    field :interval_type, Draft.IntervalTypeEnum
    field :start_date, :date
    field :end_date, :date
    field :rank, :integer

    belongs_to :employee_vacation_preference_sets, EmployeeVacationPreferenceSet,
      foreign_key: :preference_set_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_preference, attrs \\ %{}) do
    employee_vacation_preference
    |> cast(attrs, [:preference_set_id, :interval_type, :start_date, :end_date, :rank])
    |> validate_required([
      :interval_type,
      :start_date,
      :end_date,
      :rank
    ])
    |> unique_constraint([:preference_set_id, :interval_type, :start_date],
      name: :vacation_preference_interval_date_index
    )
  end
end

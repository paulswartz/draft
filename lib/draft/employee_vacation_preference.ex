defmodule Draft.EmployeeVacationPreference do
  @moduledoc """
  Represents a single vacation interval (week or day) that an employee has marked as a preference.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.EmployeeVacationPreferenceSet

  @type t :: %__MODULE__{
          preference_set_id: integer(),
          interval_type: String.t(),
          start_date: Date.t(),
          end_date: Date.t(),
          preference_rank: integer()
        }

  @derive {Jason.Encoder,
           only: [:preference_set_id, :interval_type, :start_date, :end_date, :preference_rank]}

  schema "employee_vacation_preferences" do
    field :interval_type, :string
    field :start_date, :date
    field :end_date, :date
    field :preference_rank, :integer

    belongs_to :employee_vacation_preference_sets, EmployeeVacationPreferenceSet,
      foreign_key: :preference_set_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_preference, attrs \\ %{}) do
    employee_vacation_preference
    |> cast(attrs, [:preference_set_id, :interval_type, :start_date, :end_date, :preference_rank])
    |> validate_required([
      :interval_type,
      :start_date,
      :end_date,
      :preference_rank
    ])
  end
end

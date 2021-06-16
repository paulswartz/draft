defmodule Draft.EmployeeVacationPreference do
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

  schema "employee_vacation_preferences" do
    field :preference_set_id, :integer
    field :interval_type, :string
    field :start_date, :date
    field :end_date, :date
    field :preference_rank, :integer
    belongs_to :employee_vacation_preference_sets, EmployeeVacationPreferenceSet

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(employee_vacation_preference, attrs) do
    employee_vacation_preference
    |> cast(attrs, [:preference_set_id, :interval_type, :start_date, :end_date, :preference_rank])
    |> validate_required([:preference_set_id, :interval_type, :start_date, :end_date, :preference_rank])
  end
end

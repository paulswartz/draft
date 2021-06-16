defmodule Draft.EmployeeVacationPreferenceSet do
  use Ecto.Schema
  import Ecto.Changeset
  alias Draft.EmployeeVacationPreference

  @type t :: %__MODULE__{
    employee_id: String.t(),
    process_id: String.t(),
    round_id: String.t(),
    previous_preference_set_id: integer() | nil
  }

  schema "employee_vacation_preference_sets" do
    field :employee_id, :string
    field :process_id, :string
    field :round_id, :string
    field :previous_preference_set_id, :integer
    has_many :employee_vacation_preferences, EmployeeVacationPreference

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(employee_vacation_preference_set, attrs) do
    employee_vacation_preference_set
    |> cast(attrs, [:employee_id, :process_id, :round_id, :previous_preference_set_id,])
    |> validate_required([:employee_id, :process_id, :round_id])
  end
end

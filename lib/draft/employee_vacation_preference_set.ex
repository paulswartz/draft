defmodule Draft.EmployeeVacationPreferenceSet do
  @moduledoc """
  Represents a set of vacation preferences given by an employee for a particular pick period.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Draft.EmployeeVacationPreference
  alias Draft.Repo

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
    has_many :vacation_preferences, EmployeeVacationPreference, foreign_key: :preference_set_id

    timestamps(type: :utc_datetime)
  end



  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_preference_set, attrs \\ %{}) do
    employee_vacation_preference_set
    |> cast(attrs, [:employee_id, :process_id, :round_id, :previous_preference_set_id])
    |> validate_required([:employee_id, :process_id, :round_id])
  end

  @spec get_latest_preferences(String.t(), String.t(), String.t()) ::
          __MODULE__.t()
  @doc """
  Get the most recently entered preferences entered by the given operator for the given pick.
  """
  def get_latest_preferences(process_id, round_id, employee_id) do
    latest_preference_set_query =
      from(preference_set in Draft.EmployeeVacationPreferenceSet,
        where:
          preference_set.process_id == ^process_id and preference_set.round_id == ^round_id and
            preference_set.employee_id == ^employee_id,
        order_by: [desc: preference_set.id],
        limit: 1
      )

    latest_preference_set_query
    |> Repo.one()
    |> Repo.preload(:vacation_preferences)
  end
end

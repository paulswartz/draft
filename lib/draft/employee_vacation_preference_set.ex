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
          employee_id: String.t() | nil,
          process_id: String.t() | nil,
          round_id: String.t() | nil,
          vacation_preferences: [EmployeeVacationPreference.t()] | Ecto.Association.NotLoaded.t(),
          previous_preference_set_id: integer() | nil
        }

  @derive {Jason.Encoder, only: [:employee_id, :process_id, :round_id, :vacation_preferences]}

  schema "employee_vacation_preference_sets" do
    field :employee_id, :string
    field :process_id, :string
    field :round_id, :string
    field :previous_preference_set_id, :integer
    has_many :vacation_preferences, EmployeeVacationPreference, foreign_key: :preference_set_id

    timestamps(type: :utc_datetime)
  end

  @spec create(map()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Insert a new preference set from the valid attributes given, or return a descriptive error.
  """
  def create(preference_set_attrs) do
    latest_preferences =
      get_latest_preferences(
        preference_set_attrs[:process_id],
        preference_set_attrs[:round_id],
        preference_set_attrs[:employee_id]
      )

    previous_preference_id =
      if latest_preferences == nil do
        nil
      else
        latest_preferences.id
      end

    preference_set_attrs =
      Map.put(preference_set_attrs, :previous_preference_set_id, previous_preference_id)

    preference_set_changeset = changeset(%__MODULE__{}, preference_set_attrs)

    require Logger
    Logger.error(preference_set_changeset.valid?)

    if preference_set_changeset.valid? do
      preference_set_changeset
      |> Map.put(
        :previous_preference_set_id,
        previous_preference_id
      )
      |> Repo.insert()
    else
      {:error, preference_set_changeset}
    end
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(employee_vacation_preference_set, attrs \\ %{}) do
    employee_vacation_preference_set
    |> cast(attrs, [:employee_id, :process_id, :round_id, :previous_preference_set_id])
    |> cast_assoc(:vacation_preferences)
    |> validate_required([:employee_id, :process_id, :round_id])
    |> foreign_key_constraint(:round_id, name: :employee_vacation_preference_sets_round_id_fkey)
  end

  @spec get_latest_preferences(String.t(), String.t(), String.t()) ::
          __MODULE__.t() | nil
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

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
          vacation_preferences: [EmployeeVacationPreference.t()] | Ecto.Association.NotLoaded.t(),
          previous_preference_set_id: integer()
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
    initial_struct = struct!(__MODULE__, [])

    preference_set_changeset =
      initial_struct
      |> cast(preference_set_attrs, [:employee_id, :process_id, :round_id])
      |> cast_assoc(:vacation_preferences)
      |> validate_required([:employee_id, :process_id, :round_id])
      |> foreign_key_constraint(:round_id, name: :employee_vacation_preference_sets_round_id_fkey)

    if preference_set_changeset.valid? do
      Repo.insert(preference_set_changeset)
    else
      {:error, preference_set_changeset}
    end
  end

  @spec update(map()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Update an existing preference set -- inserts a new reference set with a reference to the previous one.
  """
  def update(preference_set_attrs) do
    preference_set_changeset = changeset(struct!(__MODULE__, []), preference_set_attrs)

    if preference_set_changeset.valid? do
      Repo.insert(preference_set_changeset)
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
    |> validate_required([:employee_id, :process_id, :round_id, :previous_preference_set_id])
    |> validate_previous_id_belongs_to_employee_pick()
    |> foreign_key_constraint(:round_id, name: :employee_vacation_preference_sets_round_id_fkey)
  end

  defp validate_previous_id_belongs_to_employee_pick(changeset) do
    valid_previous_preference_set_id =
      Repo.exists?(
        from s in __MODULE__,
          where:
            s.round_id == ^get_field(changeset, :round_id) and
              s.process_id == ^get_field(changeset, :process_id) and
              s.employee_id == ^get_field(changeset, :employee_id) and
              s.id == ^get_field(changeset, :previous_preference_set_id)
      )

    if valid_previous_preference_set_id do
      changeset
    else
      add_error(
        changeset,
        :previous_preference_set_id,
        "Previous preference set with id #{get_field(changeset, :previous_preference_set_id)} not found for this user"
      )
    end
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
        limit: 1,
        preload: [
          vacation_preferences:
            ^from(
              p in EmployeeVacationPreference,
              order_by: [asc: p.rank]
            )
        ]
      )

    Repo.one(latest_preference_set_query)
  end
end
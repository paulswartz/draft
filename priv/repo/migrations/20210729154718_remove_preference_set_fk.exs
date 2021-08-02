defmodule Draft.Repo.Migrations.RemovePreferenceSetFk do
  use Ecto.Migration

  def change do
    drop constraint(
           :employee_vacation_preference_sets,
           "employee_vacation_preference_sets_round_id_fkey"
         )
  end
end

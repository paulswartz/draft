defmodule Draft.Repo.Migrations.RemovePreferenceSetFk do
  use Ecto.Migration

  def up do
    drop constraint(
           :employee_vacation_preference_sets,
           "employee_vacation_preference_sets_round_id_fkey"
         )
  end

  def down do
    # unlikely to do this in practice, so not bothering to recreate the foreign key constraint -ps
    :ok
  end
end

defmodule Draft.Repo.Migrations.AddSessionJobClassCategory do
  use Ecto.Migration

  def change do
    alter table(:bid_sessions) do
      add :job_class_category, :string
    end
  end
end

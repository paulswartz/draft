defmodule FakeMigrator do
  @moduledoc "Fake implementation of Ecto.Migrator"
  @spec with_repo(module, (module -> :ok)) :: {:ok, :ok, :ok}
  def with_repo(repo, fun) do
    :ok = fun.(repo)
    {:ok, :ok, :ok}
  end

  @spec run(module, :up, Keyword.t()) :: :ok
  def run(Draft.Repo, :up, all: true) do
    :ok
  end
end

defmodule Draft.Repo.MigratorTest do
  @moduledoc false
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Draft.Repo.Migrator

  describe "child_spec/1" do
    test "restart is transient" do
      assert %{
               restart: :transient
             } = Migrator.child_spec([])
    end
  end

  describe "start_link/1" do
    test "runs migrations and ends" do
      log_level_info()

      log =
        capture_log(fn ->
          assert :ignore = Migrator.start_link(module: FakeMigrator)
        end)

      assert log =~ "Migrating synchronously"
    end

    test "logs a migration for each repo" do
      log_level_info()

      log =
        capture_log(fn ->
          Migrator.start_link(module: FakeMigrator)
        end)

      assert log =~ "Migrating"
      assert log =~ "Migration finished"
      assert log =~ "repo=Elixir.Draft.Repo"
      assert log =~ "time="
    end
  end

  defp log_level_info do
    old_level = Logger.level()

    on_exit(fn ->
      Logger.configure(level: old_level)
    end)

    Logger.configure(level: :info)

    :ok
  end
end
